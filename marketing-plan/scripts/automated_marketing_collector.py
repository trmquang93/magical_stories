#!/usr/bin/env python3
"""
Automated Marketing Data Collector
Runs daily/weekly automated collection of all marketing metrics
"""

import os
import sys
import json
import time
import schedule
import subprocess
from datetime import datetime, timedelta
from typing import Dict, List
from pathlib import Path

class AutomatedMarketingCollector:
    """Automated scheduler for marketing data collection"""
    
    def __init__(self):
        self.script_dir = Path(__file__).parent
        self.data_dir = self.script_dir / "automated_data"
        self.data_dir.mkdir(exist_ok=True)
        
        self.log_file = self.data_dir / "collection_log.txt"
        
        # Collection scripts
        self.scripts = {
            'comprehensive': 'comprehensive_marketing_analytics.py',
            'dashboard': 'marketing_dashboard.py'
        }
        
    def log_message(self, message: str):
        """Log message with timestamp"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        log_entry = f"[{timestamp}] {message}\n"
        
        print(log_entry.strip())
        
        with open(self.log_file, 'a') as f:
            f.write(log_entry)
    
    def run_data_collection(self) -> bool:
        """Run comprehensive marketing data collection"""
        self.log_message("🚀 Starting automated marketing data collection")
        
        try:
            # Run comprehensive analytics
            comprehensive_script = self.script_dir / self.scripts['comprehensive']
            
            self.log_message(f"📊 Running {comprehensive_script}")
            result = subprocess.run([sys.executable, str(comprehensive_script)], 
                                 capture_output=True, text=True, cwd=self.script_dir)
            
            if result.returncode == 0:
                self.log_message("✅ Comprehensive analytics completed successfully")
                
                # Move generated files to automated data directory
                self.organize_generated_files()
                
                return True
            else:
                self.log_message(f"❌ Comprehensive analytics failed: {result.stderr}")
                return False
                
        except Exception as e:
            self.log_message(f"❌ Error during data collection: {e}")
            return False
    
    def run_dashboard_generation(self) -> bool:
        """Generate marketing dashboards"""
        self.log_message("🎨 Starting dashboard generation")
        
        try:
            dashboard_script = self.script_dir / self.scripts['dashboard']
            
            self.log_message(f"📈 Running {dashboard_script}")
            result = subprocess.run([sys.executable, str(dashboard_script)], 
                                 capture_output=True, text=True, cwd=self.script_dir)
            
            if result.returncode == 0:
                self.log_message("✅ Dashboard generation completed successfully")
                return True
            else:
                self.log_message(f"❌ Dashboard generation failed: {result.stderr}")
                return False
                
        except Exception as e:
            self.log_message(f"❌ Error during dashboard generation: {e}")
            return False
    
    def organize_generated_files(self):
        """Organize generated files into dated directories"""
        try:
            date_str = datetime.now().strftime('%Y-%m-%d')
            daily_dir = self.data_dir / date_str
            daily_dir.mkdir(exist_ok=True)
            
            # Move data files
            for pattern in ['marketing_*.json', 'magical_stories_*.json']:
                for file_path in self.script_dir.glob(pattern):
                    if file_path.is_file():
                        destination = daily_dir / file_path.name
                        file_path.rename(destination)
                        self.log_message(f"📁 Moved {file_path.name} to {daily_dir}")
            
            # Move dashboard files
            dashboard_dir = self.script_dir / "dashboard_outputs"
            if dashboard_dir.exists():
                daily_dashboard_dir = daily_dir / "dashboards"
                daily_dashboard_dir.mkdir(exist_ok=True)
                
                for dashboard_file in dashboard_dir.glob("*.png"):
                    destination = daily_dashboard_dir / dashboard_file.name
                    dashboard_file.rename(destination)
                    self.log_message(f"📊 Moved {dashboard_file.name} to {daily_dashboard_dir}")
            
        except Exception as e:
            self.log_message(f"❌ Error organizing files: {e}")
    
    def daily_collection_job(self):
        """Daily automated collection job"""
        self.log_message("📅 Starting daily marketing data collection job")
        
        success = self.run_data_collection()
        
        if success:
            self.log_message("✅ Daily collection completed successfully")
            
            # Generate summary report
            self.generate_daily_summary()
        else:
            self.log_message("❌ Daily collection failed")
    
    def weekly_full_analysis_job(self):
        """Weekly comprehensive analysis job"""
        self.log_message("📊 Starting weekly full marketing analysis job")
        
        # Run data collection
        data_success = self.run_data_collection()
        
        # Generate dashboards
        dashboard_success = self.run_dashboard_generation()
        
        if data_success and dashboard_success:
            self.log_message("✅ Weekly analysis completed successfully")
            
            # Generate weekly report
            self.generate_weekly_report()
        else:
            self.log_message("❌ Weekly analysis failed")
    
    def generate_daily_summary(self):
        """Generate daily collection summary"""
        try:
            date_str = datetime.now().strftime('%Y-%m-%d')
            daily_dir = self.data_dir / date_str
            
            # Find latest data files
            data_files = list(daily_dir.glob("marketing_*.json"))
            
            if not data_files:
                self.log_message("❌ No data files found for daily summary")
                return
            
            # Load latest KPI data
            kpi_files = [f for f in data_files if 'kpis' in f.name]
            if kpi_files:
                latest_kpi = max(kpi_files, key=lambda x: x.stat().st_mtime)
                
                with open(latest_kpi, 'r') as f:
                    kpis = json.load(f)
                
                # Create daily summary
                summary = {
                    "date": date_str,
                    "collection_time": datetime.now().isoformat(),
                    "data_quality": "Good" if len(data_files) >= 3 else "Partial",
                    "files_generated": len(data_files),
                    "key_metrics": {
                        "app_id": kpis.get("app_info", {}).get("app_id", "N/A"),
                        "collection_status": "Success"
                    }
                }
                
                # Save summary
                summary_file = daily_dir / "daily_summary.json"
                with open(summary_file, 'w') as f:
                    json.dump(summary, f, indent=2)
                
                self.log_message(f"📄 Daily summary saved: {summary_file}")
                
        except Exception as e:
            self.log_message(f"❌ Error generating daily summary: {e}")
    
    def generate_weekly_report(self):
        """Generate comprehensive weekly report"""
        try:
            # Find all daily data from the past week
            end_date = datetime.now()
            start_date = end_date - timedelta(days=7)
            
            weekly_data = []
            
            for i in range(7):
                check_date = start_date + timedelta(days=i)
                date_str = check_date.strftime('%Y-%m-%d')
                daily_dir = self.data_dir / date_str
                
                if daily_dir.exists():
                    summary_file = daily_dir / "daily_summary.json"
                    if summary_file.exists():
                        with open(summary_file, 'r') as f:
                            daily_data = json.load(f)
                            weekly_data.append(daily_data)
            
            # Create weekly report
            week_report = {
                "report_period": f"{start_date.strftime('%Y-%m-%d')} to {end_date.strftime('%Y-%m-%d')}",
                "generated_at": datetime.now().isoformat(),
                "days_with_data": len(weekly_data),
                "collection_success_rate": (len(weekly_data) / 7) * 100,
                "daily_summaries": weekly_data,
                "weekly_insights": {
                    "data_consistency": "Good" if len(weekly_data) >= 5 else "Needs Improvement",
                    "collection_reliability": f"{len(weekly_data)}/7 days successful",
                    "recommendations": [
                        "Monitor collection failures",
                        "Ensure all APIs are accessible",
                        "Review data quality metrics"
                    ]
                }
            }
            
            # Save weekly report
            week_dir = self.data_dir / f"weekly_reports"
            week_dir.mkdir(exist_ok=True)
            
            report_file = week_dir / f"weekly_report_{end_date.strftime('%Y%m%d')}.json"
            with open(report_file, 'w') as f:
                json.dump(week_report, f, indent=2)
            
            self.log_message(f"📊 Weekly report saved: {report_file}")
            
        except Exception as e:
            self.log_message(f"❌ Error generating weekly report: {e}")
    
    def setup_schedule(self):
        """Set up automated collection schedule"""
        self.log_message("⏰ Setting up automated collection schedule")
        
        # Daily collection at 6 AM
        schedule.every().day.at("06:00").do(self.daily_collection_job)
        
        # Weekly full analysis on Mondays at 7 AM
        schedule.every().monday.at("07:00").do(self.weekly_full_analysis_job)
        
        # Additional collections for high-frequency monitoring
        schedule.every().day.at("12:00").do(self.daily_collection_job)  # Noon
        schedule.every().day.at("18:00").do(self.daily_collection_job)  # 6 PM
        
        self.log_message("✅ Automated schedule configured:")
        self.log_message("   📅 Daily collections: 6 AM, 12 PM, 6 PM")
        self.log_message("   📊 Weekly analysis: Mondays at 7 AM")
    
    def run_scheduler(self):
        """Run the automated scheduler"""
        self.log_message("🚀 Starting automated marketing data collector")
        self.log_message(f"📁 Data directory: {self.data_dir}")
        self.log_message(f"📝 Log file: {self.log_file}")
        
        self.setup_schedule()
        
        try:
            while True:
                schedule.run_pending()
                time.sleep(60)  # Check every minute
                
        except KeyboardInterrupt:
            self.log_message("⏹️ Automated collector stopped by user")
        except Exception as e:
            self.log_message(f"❌ Scheduler error: {e}")
    
    def run_manual_collection(self):
        """Run manual collection for testing"""
        self.log_message("🔧 Running manual collection for testing")
        
        success = self.run_data_collection()
        
        if success:
            dashboard_success = self.run_dashboard_generation()
            if dashboard_success:
                self.log_message("✅ Manual collection and dashboard generation completed")
            else:
                self.log_message("⚠️ Manual collection succeeded but dashboard generation failed")
        else:
            self.log_message("❌ Manual collection failed")

def main():
    """Main execution function"""
    print("🤖 Automated Marketing Data Collector for Magical Stories")
    print("⏰ Schedules daily and weekly marketing analytics collection")
    print("=" * 65)
    
    try:
        collector = AutomatedMarketingCollector()
        
        # Check command line arguments
        if len(sys.argv) > 1:
            if sys.argv[1] == "--manual":
                collector.run_manual_collection()
                return
            elif sys.argv[1] == "--test":
                print("🧪 Testing collection scripts...")
                collector.run_manual_collection()
                return
            elif sys.argv[1] == "--help":
                print("Usage:")
                print("  python automated_marketing_collector.py          # Run automated scheduler")
                print("  python automated_marketing_collector.py --manual # Run manual collection")
                print("  python automated_marketing_collector.py --test   # Test collection scripts")
                return
        
        # Check dependencies
        try:
            import schedule
        except ImportError:
            print("❌ Install schedule dependency: pip3 install schedule")
            print("💡 Or run with --manual for one-time collection")
            return
        
        # Run automated scheduler
        collector.run_scheduler()
        
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()