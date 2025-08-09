#!/usr/bin/env python3
"""
Marketing Analytics Setup Script
Automated setup and configuration for Magical Stories marketing analytics system
"""

import os
import sys
import subprocess
import json
from datetime import datetime
from pathlib import Path

class MarketingAnalyticsSetup:
    """Complete setup for marketing analytics system"""
    
    def __init__(self):
        self.script_dir = Path(__file__).parent
        self.project_root = self.script_dir.parent
        
        # Required dependencies
        self.dependencies = [
            'PyJWT>=2.8.0',
            'cryptography>=41.0.0', 
            'requests>=2.31.0',
            'matplotlib>=3.7.0',
            'seaborn>=0.12.0',
            'schedule>=1.2.0'
        ]
        
        # Directory structure to create
        self.directories = [
            'automated_data',
            'dashboard_outputs',
            'automated_data/weekly_reports',
            'logs'
        ]
        
        # Scripts to validate
        self.scripts = [
            'comprehensive_marketing_analytics.py',
            'marketing_dashboard.py', 
            'automated_marketing_collector.py',
            'magical_stories_analytics.py',
            'appstore_auth_test.py'
        ]
        
    def log_message(self, message: str, level: str = "INFO"):
        """Log setup progress"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        prefix = {
            "INFO": "ℹ️",
            "SUCCESS": "✅", 
            "WARNING": "⚠️",
            "ERROR": "❌"
        }.get(level, "ℹ️")
        
        log_message = f"[{timestamp}] {prefix} {message}"
        print(log_message)
        
        # Also log to file
        log_file = self.script_dir / "logs" / "setup.log"
        log_file.parent.mkdir(exist_ok=True)
        
        with open(log_file, 'a') as f:
            f.write(f"{log_message}\n")
    
    def check_python_version(self) -> bool:
        """Check if Python version is compatible"""
        self.log_message("Checking Python version...")
        
        version = sys.version_info
        if version.major == 3 and version.minor >= 7:
            self.log_message(f"Python {version.major}.{version.minor}.{version.micro} - Compatible", "SUCCESS")
            return True
        else:
            self.log_message(f"Python {version.major}.{version.minor}.{version.micro} - Requires Python 3.7+", "ERROR")
            return False
    
    def install_dependencies(self) -> bool:
        """Install all required Python packages"""
        self.log_message("Installing required dependencies...")
        
        try:
            for package in self.dependencies:
                self.log_message(f"Installing {package}...")
                result = subprocess.run([
                    sys.executable, '-m', 'pip', 'install', package, '--upgrade'
                ], capture_output=True, text=True)
                
                if result.returncode == 0:
                    self.log_message(f"✓ {package} installed successfully", "SUCCESS")
                else:
                    self.log_message(f"Failed to install {package}: {result.stderr}", "ERROR")
                    return False
            
            return True
            
        except Exception as e:
            self.log_message(f"Error installing dependencies: {e}", "ERROR")
            return False
    
    def create_directory_structure(self) -> bool:
        """Create required directory structure"""
        self.log_message("Creating directory structure...")
        
        try:
            for directory in self.directories:
                dir_path = self.script_dir / directory
                dir_path.mkdir(parents=True, exist_ok=True)
                self.log_message(f"✓ Created directory: {directory}", "SUCCESS")
            
            return True
            
        except Exception as e:
            self.log_message(f"Error creating directories: {e}", "ERROR")
            return False
    
    def validate_scripts(self) -> bool:
        """Validate that all required scripts exist"""
        self.log_message("Validating script files...")
        
        all_valid = True
        
        for script in self.scripts:
            script_path = self.script_dir / script
            if script_path.exists():
                self.log_message(f"✓ Found: {script}", "SUCCESS")
            else:
                self.log_message(f"Missing: {script}", "ERROR")
                all_valid = False
        
        return all_valid
    
    def check_api_credentials(self) -> bool:
        """Check App Store Connect API credentials"""
        self.log_message("Checking App Store Connect API credentials...")
        
        key_path = "/Users/quang.tranminh/Library/Mobile Documents/com~apple~CloudDocs/DevelopmentCertificates/AuthKey_RHM24L7VXD.p8"
        
        if os.path.exists(key_path):
            self.log_message("✓ App Store Connect private key found", "SUCCESS")
            return True
        else:
            self.log_message(f"Private key not found at: {key_path}", "WARNING")
            self.log_message("API authentication may fail without proper credentials", "WARNING")
            return False
    
    def test_authentication(self) -> bool:
        """Test App Store Connect authentication"""
        self.log_message("Testing App Store Connect authentication...")
        
        try:
            auth_script = self.script_dir / "appstore_auth_test.py"
            if not auth_script.exists():
                self.log_message("Authentication test script not found", "WARNING")
                return False
            
            result = subprocess.run([
                sys.executable, str(auth_script)
            ], capture_output=True, text=True, cwd=self.script_dir, timeout=30)
            
            if result.returncode == 0:
                self.log_message("✓ App Store Connect authentication successful", "SUCCESS")
                return True
            else:
                self.log_message(f"Authentication test failed: {result.stderr}", "WARNING")
                return False
                
        except subprocess.TimeoutExpired:
            self.log_message("Authentication test timed out", "WARNING")
            return False
        except Exception as e:
            self.log_message(f"Error testing authentication: {e}", "WARNING")
            return False
    
    def run_initial_data_collection(self) -> bool:
        """Run initial marketing data collection"""
        self.log_message("Running initial marketing data collection...")
        
        try:
            collection_script = self.script_dir / "comprehensive_marketing_analytics.py"
            if not collection_script.exists():
                self.log_message("Comprehensive analytics script not found", "ERROR")
                return False
            
            result = subprocess.run([
                sys.executable, str(collection_script)  
            ], capture_output=True, text=True, cwd=self.script_dir, timeout=60)
            
            if result.returncode == 0:
                self.log_message("✓ Initial data collection completed", "SUCCESS")
                
                # Check if files were generated
                data_files = list(self.script_dir.glob("marketing_*.json"))
                if data_files:
                    self.log_message(f"✓ Generated {len(data_files)} data files", "SUCCESS")
                    return True
                else:
                    self.log_message("No data files generated", "WARNING")
                    return False
            else:
                self.log_message(f"Data collection failed: {result.stderr}", "ERROR")
                return False
                
        except subprocess.TimeoutExpired:
            self.log_message("Data collection timed out", "ERROR")
            return False
        except Exception as e:
            self.log_message(f"Error running data collection: {e}", "ERROR")
            return False
    
    def generate_initial_dashboards(self) -> bool:
        """Generate initial marketing dashboards"""
        self.log_message("Generating initial marketing dashboards...")
        
        try:
            dashboard_script = self.script_dir / "marketing_dashboard.py"
            if not dashboard_script.exists():
                self.log_message("Dashboard script not found", "ERROR")
                return False
            
            result = subprocess.run([
                sys.executable, str(dashboard_script)
            ], capture_output=True, text=True, cwd=self.script_dir, timeout=60)
            
            if result.returncode == 0:
                self.log_message("✓ Initial dashboards generated", "SUCCESS")
                
                # Check dashboard outputs
                dashboard_dir = self.script_dir / "dashboard_outputs"
                if dashboard_dir.exists():
                    dashboard_files = list(dashboard_dir.glob("*.png"))
                    self.log_message(f"✓ Generated {len(dashboard_files)} dashboard images", "SUCCESS")
                    return True
                else:
                    self.log_message("No dashboard files generated", "WARNING")
                    return False
            else:
                self.log_message(f"Dashboard generation failed: {result.stderr}", "ERROR")
                return False
                
        except subprocess.TimeoutExpired:
            self.log_message("Dashboard generation timed out", "ERROR")
            return False
        except Exception as e:
            self.log_message(f"Error generating dashboards: {e}", "ERROR")
            return False
    
    def create_setup_summary(self, results: dict) -> str:
        """Create setup summary report"""
        self.log_message("Creating setup summary...")
        
        summary = {
            "setup_completed_at": datetime.now().isoformat(),
            "setup_results": results,
            "system_info": {
                "python_version": f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}",
                "script_directory": str(self.script_dir),
                "dependencies_installed": all(results.get(key, False) for key in ["dependencies", "directories"]),
                "authentication_working": results.get("authentication", False),
                "data_collection_working": results.get("data_collection", False),
                "dashboards_working": results.get("dashboards", False)
            },
            "next_steps": [
                "Review generated data files in the scripts directory",
                "Check dashboard outputs in dashboard_outputs/",
                "Set up automated collection with: python3 automated_marketing_collector.py --manual",
                "Configure additional API integrations as needed"
            ]
        }
        
        # Save summary
        summary_file = self.script_dir / "setup_summary.json"
        with open(summary_file, 'w') as f:
            json.dump(summary, f, indent=2)
        
        self.log_message(f"✓ Setup summary saved: {summary_file}", "SUCCESS")
        return str(summary_file)
    
    def run_complete_setup(self) -> bool:
        """Run complete marketing analytics setup"""
        self.log_message("🚀 Starting Marketing Analytics Setup for Magical Stories")
        self.log_message("=" * 65)
        
        # Track setup results
        results = {}
        
        # 1. Check Python version
        results["python_version"] = self.check_python_version()
        if not results["python_version"]:
            self.log_message("Setup failed: Incompatible Python version", "ERROR")
            return False
        
        # 2. Install dependencies
        self.log_message("\n📦 INSTALLING DEPENDENCIES")
        self.log_message("-" * 30)
        results["dependencies"] = self.install_dependencies()
        
        # 3. Create directory structure
        self.log_message("\n📁 CREATING DIRECTORY STRUCTURE")
        self.log_message("-" * 30)
        results["directories"] = self.create_directory_structure()
        
        # 4. Validate scripts
        self.log_message("\n📄 VALIDATING SCRIPTS") 
        self.log_message("-" * 30)
        results["scripts"] = self.validate_scripts()
        
        # 5. Check API credentials
        self.log_message("\n🔑 CHECKING API CREDENTIALS")
        self.log_message("-" * 30)
        results["credentials"] = self.check_api_credentials()
        
        # 6. Test authentication (optional - may fail without proper credentials)
        self.log_message("\n🔐 TESTING AUTHENTICATION")
        self.log_message("-" * 30)
        results["authentication"] = self.test_authentication()
        
        # 7. Run initial data collection
        self.log_message("\n📊 RUNNING INITIAL DATA COLLECTION")
        self.log_message("-" * 30)
        results["data_collection"] = self.run_initial_data_collection()
        
        # 8. Generate initial dashboards  
        self.log_message("\n📈 GENERATING DASHBOARDS")
        self.log_message("-" * 30)
        results["dashboards"] = self.generate_initial_dashboards()
        
        # 9. Create setup summary
        self.log_message("\n📄 CREATING SETUP SUMMARY")
        self.log_message("-" * 30)
        summary_file = self.create_setup_summary(results)
        
        # Final assessment
        self.log_message("\n🎯 SETUP COMPLETE")
        self.log_message("=" * 65)
        
        critical_components = ["python_version", "dependencies", "directories", "scripts"]
        critical_success = all(results.get(component, False) for component in critical_components)
        
        if critical_success:
            self.log_message("✅ Marketing Analytics System Setup Successful!", "SUCCESS")
            self.log_message(f"📊 Summary report: {summary_file}", "SUCCESS")
            
            # Display next steps
            print("\n🚀 NEXT STEPS:")
            print("1. Review setup summary and generated files")
            print("2. Test manual collection: python3 automated_marketing_collector.py --manual")  
            print("3. Set up automation: python3 automated_marketing_collector.py")
            print("4. Configure additional API integrations as needed")
            
            return True
        else:
            self.log_message("❌ Setup completed with issues. Check logs for details.", "WARNING")
            return False

def main():
    """Main setup execution"""
    print("🎯 Magical Stories Marketing Analytics Setup")
    print("🔧 Automated setup and configuration system")
    print("=" * 55)
    
    try:
        setup = MarketingAnalyticsSetup()
        success = setup.run_complete_setup()
        
        if success:
            print("\n✅ Setup completed successfully!")
            print("🎯 Marketing analytics system is ready to use")
        else:
            print("\n⚠️ Setup completed with some issues")
            print("📝 Check the setup log for details")
        
    except KeyboardInterrupt:
        print("\n❌ Setup interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Setup failed with error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()