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
    - SNOWFLAKE_PASSWORD
    - SNOWFLAKE_WAREHOUSE
    - SNOWFLAKE_DATABASE
    - SNOWFLAKE_ROLE
    - ENVIRONMENT (dev/staging/prod)
    - DRY_RUN (true/false)
"""

import os
import sys
import glob
import re
from datetime import datetime
from pathlib import Path

try:
    import snowflake.connector
except ImportError:
    print("ERROR: snowflake-connector-python not installed")
    print("Run: pip install snowflake-connector-python")
    sys.exit(1)


class SnowflakeDeployer:
    """Handles Snowflake object deployments."""

    def __init__(self):
        self.account = os.environ.get("SNOWFLAKE_ACCOUNT")
        self.user = os.environ.get("SNOWFLAKE_USER")
        self.password = os.environ.get("SNOWFLAKE_PASSWORD")
        self.warehouse = os.environ.get("SNOWFLAKE_WAREHOUSE")
        self.database = os.environ.get("SNOWFLAKE_DATABASE")
        self.role = os.environ.get("SNOWFLAKE_ROLE")
        self.environment = os.environ.get("ENVIRONMENT", "dev")
        self.dry_run = os.environ.get("DRY_RUN", "false").lower() == "true"
        
        self.conn = None
        self.cursor = None
        self.base_path = Path(__file__).parent.parent / "snowflake"
        
        # Validate required environment variables
        self._validate_config()

    def _validate_config(self):
        """Validate required configuration."""
        required = [
            "SNOWFLAKE_ACCOUNT",
            "SNOWFLAKE_USER", 
            "SNOWFLAKE_PASSWORD",
            "SNOWFLAKE_WAREHOUSE",
            "SNOWFLAKE_DATABASE",
            "SNOWFLAKE_ROLE"
        ]
        
        missing = [var for var in required if not os.environ.get(var)]
        
        if missing:
            print(f"ERROR: Missing required environment variables: {', '.join(missing)}")
            sys.exit(1)

    def connect(self):
        """Establish connection to Snowflake."""
        print(f"\n{'='*60}")
        print("Connecting to Snowflake...")
        print(f"Account: {self.account}")
        print(f"User: {self.user}")
        print(f"Database: {self.database}")
        print(f"Warehouse: {self.warehouse}")
        print(f"Role: {self.role}")
        print(f"Environment: {self.environment}")
        print(f"Dry Run: {self.dry_run}")
        print(f"{'='*60}\n")

        try:
            self.conn = snowflake.connector.connect(
                account=self.account,
                user=self.user,
                password=self.password,
                warehouse=self.warehouse,
                database=self.database,
                role=self.role
            )
            self.cursor = self.conn.cursor()
            print("✅ Connected successfully!\n")
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
        
        replacements = {
            "{{WAREHOUSE_NAME}}": f"{prefix}_ETL_WH",
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
        
        if self.dry_run:
            print(f"[DRY RUN] Would execute: {description}")
            print(f"SQL Preview:\n{sql[:500]}...")
            return True
        
        try:
            # Split into individual statements
            statements = [s.strip() for s in sql.split(';') if s.strip()]
            
            for stmt in statements:
                if stmt:
                    self.cursor.execute(stmt)
                    print(f"  ✅ Executed: {stmt[:60]}...")
            
            return True
        except Exception as e:
            print(f"  ❌ Error: {e}")
            return False

    def deploy_migrations(self):
        """Deploy versioned migrations."""
        print("\n" + "="*60)
        print("DEPLOYING MIGRATIONS")
        print("="*60)
        
        migrations_path = self.base_path / "migrations"
        
        if not migrations_path.exists():
            print("No migrations directory found")
            return
        
        # Get migration files sorted by version
        migration_files = sorted(migrations_path.glob("V*.sql"))
        
        if not migration_files:
            print("No migration files found")
            return
        
        print(f"Found {len(migration_files)} migration(s)\n")
        
        for migration_file in migration_files:
            print(f"\n📄 Processing: {migration_file.name}")
            
            with open(migration_file, 'r') as f:
                sql_content = f.read()
            
            success = self._execute_sql(sql_content, migration_file.name)
            
            if success:
                print(f"✅ Migration completed: {migration_file.name}")
            else:
                print(f"❌ Migration failed: {migration_file.name}")
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
            
            # Deploy in order: migrations -> stored procedures -> views
            self.deploy_migrations()
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

