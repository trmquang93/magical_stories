#!/usr/bin/env python3
"""
Update Marketing Data with Real App Store Connect Values
Updates the collected data with actual values from App Store Connect dashboard
"""

import json
import os
from datetime import datetime

def update_marketing_data_with_real_values():
    """Update the marketing data with the actual values from App Store Connect dashboard"""
    
    # Real values from your App Store Connect dashboard screenshot
    real_metrics = {
        "impressions": {"value": "1.52K", "change": "0%", "numeric_value": 1520},
        "product_page_views": {"value": "59", "change": "0%", "numeric_value": 59},
        "conversion_rate": {"value": "1.57%", "change": "0%", "daily_average": True, "numeric_value": 1.57},
        "total_downloads": {"value": "26", "change": "0%", "numeric_value": 26},
        "proceeds": {"value": "$0", "change": "0%", "numeric_value": 0},
        "proceeds_per_paying_user": {"value": "$0", "change": "0%", "daily_average": True, "numeric_value": 0},
        "sessions_per_active_device": {"value": "3.89", "change": "0%", "opt_in_only": True, "numeric_value": 3.89},
        "crashes": {"value": "0", "change": "0%", "opt_in_only": True, "numeric_value": 0}
    }
    
    # Find the latest marketing data file
    data_files = [f for f in os.listdir('.') if f.startswith('marketing_raw_data_') and f.endswith('.json')]
    
    if not data_files:
        print("❌ No marketing data files found. Run comprehensive_marketing_analytics.py first.")
        return None
    
    latest_file = sorted(data_files)[-1]
    print(f"📂 Updating data file: {latest_file}")
    
    # Load existing data
    with open(latest_file, 'r') as f:
        data = json.load(f)
    
    # Update the overview metrics with real values
    if 'analytics' not in data:
        data['analytics'] = {}
    if 'overview' not in data['analytics']:
        data['analytics']['overview'] = {}
    
    data['analytics']['overview']['overview_metrics'] = real_metrics
    data['analytics']['overview']['data_source'] = "App Store Connect Dashboard Screenshot"
    data['analytics']['overview']['last_updated'] = datetime.now().isoformat()
    
    # Save updated data
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    updated_filename = f"marketing_raw_data_updated_{timestamp}.json"
    
    with open(updated_filename, 'w') as f:
        json.dump(data, f, indent=2)
    
    print(f"✅ Updated data saved as: {updated_filename}")
    
    # Also update the KPIs with real values
    kpi_files = [f for f in os.listdir('.') if f.startswith('marketing_kpis_') and f.endswith('.json')]
    if kpi_files:
        latest_kpi_file = sorted(kpi_files)[-1]
        with open(latest_kpi_file, 'r') as f:
            kpi_data = json.load(f)
        
        # Update user acquisition KPIs
        kpi_data['user_acquisition']['impressions'] = real_metrics['impressions']['numeric_value']
        kpi_data['user_acquisition']['product_page_views'] = real_metrics['product_page_views']['numeric_value']
        kpi_data['user_acquisition']['conversion_rate'] = real_metrics['conversion_rate']['value']
        kpi_data['user_acquisition']['total_downloads'] = real_metrics['total_downloads']['numeric_value']
        
        # Update engagement KPIs
        kpi_data['engagement']['sessions_per_active_device'] = real_metrics['sessions_per_active_device']['numeric_value']
        kpi_data['engagement']['crashes'] = real_metrics['crashes']['numeric_value']
        
        # Update revenue KPIs
        kpi_data['revenue']['proceeds'] = real_metrics['proceeds']['value']
        kpi_data['revenue']['proceeds_per_paying_user'] = real_metrics['proceeds_per_paying_user']['value']
        
        # Save updated KPIs
        updated_kpi_filename = f"marketing_kpis_updated_{timestamp}.json"
        with open(updated_kpi_filename, 'w') as f:
            json.dump(kpi_data, f, indent=2)
        
        print(f"✅ Updated KPIs saved as: {updated_kpi_filename}")
    
    return updated_filename

def main():
    """Main execution function"""
    print("🔄 Updating Marketing Data with Real App Store Connect Values")
    print("=" * 60)
    
    updated_file = update_marketing_data_with_real_values()
    
    if updated_file:
        print(f"\n📊 REAL METRICS SUMMARY:")
        print(f"   📈 Impressions: 1,520")
        print(f"   👁️  Product Page Views: 59")
        print(f"   📱 Conversion Rate: 1.57%")
        print(f"   ⬇️  Total Downloads: 26")
        print(f"   💰 Proceeds: $0")
        print(f"   👥 Proceeds per Paying User: $0")
        print(f"   🔄 Sessions per Active Device: 3.89")
        print(f"   💥 Crashes: 0")
        
        print(f"\n🎯 Next Steps:")
        print(f"   1. Run appstore_dashboard_visualizer.py to create updated visualizations")
        print(f"   2. Use this data for marketing analysis and optimization")
        print(f"   3. Compare these metrics with your marketing goals")

if __name__ == "__main__":
    main()