#!/usr/bin/env python3
"""
=============================================================================
MB SNOWFLAKE DEVOPS DEMO
Snowflake Objects Deployment Script
=============================================================================

This script handles the deployment of Snowflake database objects including:
- SQL Migrations (version-controlled)
- Stored Procedures
- Views
- Other database objects

Usage:
    python deploy_objects.py

Environment Variables Required:
    - SNOWFLAKE_ACCOUNT
    - SNOWFLAKE_USER
    - SNOWFLAKE_AUTHENTICATOR (JWT for key-pair auth)
    - SNOWFLAKE_PRIVATE_KEY_PATH (for key-pair auth)
    - SNOWFLAKE_PASSWORD (for password auth)
    - SNOWFLAKE_WAREHOUSE
    - SNOWFLAKE_DATABASE
    - SNOWFLAKE_ROLE
    - ENVIRONMENT (dev/staging/prod)
    - DRY_RUN (true/false)
"""

import os
import sys
from datetime import datetime
from pathlib import Path

try:
    import snowflake.connector
except ImportError:
    print("ERROR: snowflake-connector-python not installed")
    print("Run: pip install snowflake-connector-python")
    sys.exit(1)

try:
    from cryptography.hazmat.backends import default_backend
    from cryptography.hazmat.primitives import serialization
    CRYPTO_AVAILABLE = True
except ImportError:
    CRYPTO_AVAILABLE = False


class SnowflakeDeployer:
    """Handles Snowflake object deployments."""

    def __init__(self):
        self.account = os.environ.get("SNOWFLAKE_ACCOUNT")
        self.user = os.environ.get("SNOWFLAKE_USER")
        self.password = os.environ.get("SNOWFLAKE_PASSWORD")
        self.authenticator = os.environ.get("SNOWFLAKE_AUTHENTICATOR")
        self.private_key_path = os.environ.get("SNOWFLAKE_PRIVATE_KEY_PATH")
        self.private_key_passphrase = os.environ.get("SNOWFLAKE_PRIVATE_KEY_PASSPHRASE")
        self.warehouse = os.environ.get("SNOWFLAKE_WAREHOUSE")
        self.database = os.environ.get("SNOWFLAKE_DATABASE")
        self.role = os.environ.get("SNOWFLAKE_ROLE")
        self.environment = os.environ.get("ENVIRONMENT", "dev")
        self.dry_run = os.environ.get("DRY_RUN", "false").lower() == "true"
        
        self.conn = None
        self.cursor = None
        self.private_key = None
        self.base_path = Path(__file__).parent.parent / "snowflake"
        
        # Validate required environment variables
        self._validate_config()
        
        # Load private key if using key-pair auth
        if self.private_key_path and self.authenticator == "JWT":
            self._load_private_key()

    def _validate_config(self):
        """Validate required configuration."""
        required_base = [
            "SNOWFLAKE_ACCOUNT",
            "SNOWFLAKE_USER",
            "SNOWFLAKE_WAREHOUSE",
            "SNOWFLAKE_DATABASE",
            "SNOWFLAKE_ROLE"
        ]
        
        missing = [var for var in required_base if not os.environ.get(var)]
        
        # Check for either password or private key
        has_password = bool(os.environ.get("SNOWFLAKE_PASSWORD"))
        has_private_key = bool(os.environ.get("SNOWFLAKE_PRIVATE_KEY_PATH"))
        
        if not has_password and not has_private_key:
            missing.append("SNOWFLAKE_PASSWORD or SNOWFLAKE_PRIVATE_KEY_PATH")
        
        if missing:
            print(f"ERROR: Missing required environment variables: {', '.join(missing)}")
            sys.exit(1)
        
        if has_private_key and not CRYPTO_AVAILABLE:
            print("ERROR: cryptography package required for key-pair authentication")
            print("Run: pip install cryptography")
            sys.exit(1)

    def _load_private_key(self):
        """Load private key for key-pair authentication."""
        key_path = os.path.expanduser(self.private_key_path)
        
        if not os.path.exists(key_path):
            print(f"ERROR: Private key file not found: {key_path}")
            sys.exit(1)
        
        try:
            with open(key_path, 'rb') as key_file:
                passphrase = self.private_key_passphrase.encode() if self.private_key_passphrase else None
                p_key = serialization.load_pem_private_key(
                    key_file.read(),
                    password=passphrase,
                    backend=default_backend()
                )
                
            self.private_key = p_key.private_bytes(
                encoding=serialization.Encoding.DER,
                format=serialization.PrivateFormat.PKCS8,
                encryption_algorithm=serialization.NoEncryption()
            )
            print("✅ Private key loaded successfully")
        except Exception as e:
            print(f"ERROR: Failed to load private key: {e}")
            sys.exit(1)

    def connect(self):
        """Establish connection to Snowflake."""
        auth_method = "key-pair" if self.private_key else "password"
        
        print(f"\n{'='*60}")
        print("Connecting to Snowflake...")
        print(f"Account: {self.account}")
        print(f"User: {self.user}")
        print(f"Auth Method: {auth_method}")
        print(f"Database: {self.database}")
        print(f"Warehouse: {self.warehouse}")
        print(f"Role: {self.role}")
        print(f"Environment: {self.environment}")
        print(f"Dry Run: {self.dry_run}")
        print(f"{'='*60}\n")

        try:
            # Build connection parameters
            conn_params = {
                "account": self.account,
                "user": self.user,
                "warehouse": self.warehouse,
                "database": self.database,
                "role": self.role
            }
            
            # Use key-pair or password authentication
            if self.private_key:
                conn_params["private_key"] = self.private_key
            else:
                conn_params["password"] = self.password
            
            self.conn = snowflake.connector.connect(**conn_params)
            self.cursor = self.conn.cursor()
            print(f"✅ Connected successfully using {auth_method} authentication!\n")
        except Exception as e:
            print(f"❌ Connection failed: {e}")
            sys.exit(1)

    def disconnect(self):
        """Close Snowflake connection."""
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()
        print("\n✅ Disconnected from Snowflake")

    def _replace_placeholders(self, sql_content: str) -> str:
        """Replace placeholders in SQL with environment-specific values."""
        # Define placeholder mappings based on environment
        prefix = f"MB_DEMO_{self.environment.upper()}"
        
        # Use configured warehouse from env var, or fall back to environment-specific
        warehouse = self.warehouse or f"{prefix}_ETL_WH"
        
        replacements = {
            "{{WAREHOUSE_NAME}}": warehouse,
            "{{DATABASE_NAME}}": f"{prefix}_ANALYTICS",
            "{{ROLE_PREFIX}}": prefix,
            "{{ENVIRONMENT}}": self.environment.upper(),
        }
        
        for placeholder, value in replacements.items():
            sql_content = sql_content.replace(placeholder, value)
        
        return sql_content

    def _execute_sql(self, sql: str, description: str = ""):
        """Execute SQL statement."""
        # Replace placeholders
        sql = self._replace_placeholders(sql)
        
        # Clean up the SQL - remove trailing whitespace and empty lines
        sql = sql.strip()
        
        # Remove trailing semicolon if present (execute_string adds its own)
        if sql.endswith(';'):
            sql = sql[:-1].strip()
        
        if self.dry_run:
            print(f"[DRY RUN] Would execute: {description}")
            print(f"SQL Preview:\n{sql[:500]}...")
            return True
        
        try:
            # Use execute_string to handle multi-statement SQL properly
            # This handles CREATE TASK with embedded MERGE statements
            # remove_comments=True helps avoid issues with comment-only sections
            results = self.conn.execute_string(sql, return_cursors=True, remove_comments=True)
            
            for cursor in results:
                # Get the first few chars of the query for logging
                query_preview = cursor.query[:60] if cursor.query else "Unknown"
                print(f"  ✅ Executed: {query_preview}...")
            
            return True
        except Exception as e:
            print(f"  ❌ Error: {e}")
            return False

    def deploy_ddl(self):
        """Deploy versioned DDL scripts."""
        print("\n" + "="*60)
        print("DEPLOYING DDL SCRIPTS")
        print("="*60)
        
        ddl_path = self.base_path / "ddl"
        
        if not ddl_path.exists():
            print("No ddl directory found")
            return
        
        # Get DDL files sorted by version
        ddl_files = sorted(ddl_path.glob("V*.sql"))
        
        if not ddl_files:
            print("No DDL files found")
            return
        
        print(f"Found {len(ddl_files)} DDL script(s)\n")
        
        for ddl_file in ddl_files:
            print(f"\n📄 Processing: {ddl_file.name}")
            
            with open(ddl_file, 'r') as f:
                sql_content = f.read()
            
            success = self._execute_sql(sql_content, ddl_file.name)
            
            if success:
                print(f"✅ DDL completed: {ddl_file.name}")
            else:
                print(f"❌ DDL failed: {ddl_file.name}")
                if not self.dry_run:
                    sys.exit(1)

    def deploy_stored_procedures(self):
        """Deploy stored procedures."""
        print("\n" + "="*60)
        print("DEPLOYING STORED PROCEDURES")
        print("="*60)
        
        sp_path = self.base_path / "objects" / "stored_procedures"
        
        if not sp_path.exists():
            print("No stored procedures directory found")
            return
        
        sp_files = list(sp_path.glob("*.sql"))
        
        if not sp_files:
            print("No stored procedure files found")
            return
        
        print(f"Found {len(sp_files)} stored procedure(s)\n")
        
        for sp_file in sp_files:
            print(f"\n📄 Processing: {sp_file.name}")
            
            with open(sp_file, 'r') as f:
                sql_content = f.read()
            
            success = self._execute_sql(sql_content, sp_file.name)
            
            if success:
                print(f"✅ Stored procedure deployed: {sp_file.name}")
            else:
                print(f"❌ Stored procedure failed: {sp_file.name}")

    def deploy_views(self):
        """Deploy views."""
        print("\n" + "="*60)
        print("DEPLOYING VIEWS")
        print("="*60)
        
        views_path = self.base_path / "objects" / "views"
        
        if not views_path.exists():
            print("No views directory found")
            return
        
        view_files = list(views_path.glob("*.sql"))
        
        if not view_files:
            print("No view files found")
            return
        
        print(f"Found {len(view_files)} view file(s)\n")
        
        for view_file in view_files:
            print(f"\n📄 Processing: {view_file.name}")
            
            with open(view_file, 'r') as f:
                sql_content = f.read()
            
            success = self._execute_sql(sql_content, view_file.name)
            
            if success:
                print(f"✅ Views deployed: {view_file.name}")
            else:
                print(f"❌ Views failed: {view_file.name}")

    def run(self):
        """Run full deployment."""
        start_time = datetime.now()
        
        print("\n" + "="*60)
        print("MB SNOWFLAKE DEVOPS DEMO")
        print("Database Objects Deployment")
        print(f"Started at: {start_time.isoformat()}")
        print("="*60)
        
        try:
            self.connect()
            
            # Deploy in order: DDL -> stored procedures -> views
            self.deploy_ddl()
            self.deploy_stored_procedures()
            self.deploy_views()
            
            self.disconnect()
            
            end_time = datetime.now()
            duration = (end_time - start_time).total_seconds()
            
            print("\n" + "="*60)
            print("DEPLOYMENT SUMMARY")
            print("="*60)
            print(f"Environment: {self.environment}")
            print(f"Dry Run: {self.dry_run}")
            print(f"Duration: {duration:.2f} seconds")
            print(f"Status: ✅ SUCCESS")
            print("="*60 + "\n")
            
        except Exception as e:
            print(f"\n❌ Deployment failed: {e}")
            sys.exit(1)


if __name__ == "__main__":
    deployer = SnowflakeDeployer()
    deployer.run()

