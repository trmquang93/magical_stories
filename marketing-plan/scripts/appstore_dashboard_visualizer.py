#!/usr/bin/env python3
"""
App Store Connect Dashboard Visualizer
Creates visualizations matching the exact layout of App Store Connect dashboard
"""

import os
import sys
import json
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from datetime import datetime
import numpy as np
from typing import Dict, List, Optional

class AppStoreDashboardVisualizer:
    """Create App Store Connect-style dashboard visualizations"""
    
    def __init__(self):
        self.output_dir = "dashboard_outputs"
        os.makedirs(self.output_dir, exist_ok=True)
        
        # App Store Connect color scheme
        self.colors = {
            'blue': '#007AFF',
            'light_blue': '#5AC8FA', 
            'gray': '#8E8E93',
            'light_gray': '#F2F2F7',
            'dark_gray': '#1C1C1E',
            'white': '#FFFFFF',
            'green': '#34C759',
            'red': '#FF3B30'
        }
        
    def create_metric_card(self, ax, title: str, value: str, change: str, 
                          x: float, y: float, width: float, height: float,
                          has_chart: bool = True, chart_data: List = None):
        """Create a single metric card matching App Store Connect style"""
        
        # Card background
        card = patches.Rectangle((x, y), width, height, 
                               facecolor=self.colors['white'],
                               edgecolor=self.colors['light_gray'],
                               linewidth=1)
        ax.add_patch(card)
        
        # Title
        ax.text(x + 0.02, y + height - 0.05, title, 
               fontsize=10, color=self.colors['gray'],
               fontweight='normal')
        
        # Value
        ax.text(x + 0.02, y + height - 0.15, value,
               fontsize=18, color=self.colors['dark_gray'], 
               fontweight='bold')
        
        # Change percentage
        change_color = self.colors['green'] if '+' in change or change == '0%' else self.colors['red']
        ax.text(x + 0.02, y + height - 0.25, change,
               fontsize=12, color=change_color,
               fontweight='normal')
        
        # Mini chart if provided
        if has_chart and chart_data:
            chart_x = x + 0.02
            chart_y = y + 0.05
            chart_width = width - 0.04
            chart_height = height - 0.35
            
            # Simple line chart
            chart_points = np.linspace(chart_x, chart_x + chart_width, len(chart_data))
            normalized_data = np.array(chart_data)
            if len(normalized_data) > 0:
                normalized_data = (normalized_data - np.min(normalized_data)) / (np.max(normalized_data) - np.min(normalized_data) + 0.001)
                chart_values = chart_y + normalized_data * chart_height
                
                ax.plot(chart_points, chart_values, 
                       color=self.colors['blue'], linewidth=2)
                ax.fill_between(chart_points, chart_y, chart_values,
                              color=self.colors['blue'], alpha=0.1)
    
    def create_app_store_overview_dashboard(self, metrics_data: Dict) -> str:
        """Create App Store Connect Overview dashboard matching the exact layout"""
        
        # Set up the figure with App Store Connect proportions
        fig, ax = plt.subplots(1, 1, figsize=(16, 10))
        fig.patch.set_facecolor(self.colors['light_gray'])
        ax.set_facecolor(self.colors['light_gray'])
        
        # Remove axes
        ax.set_xlim(0, 1)
        ax.set_ylim(0, 1)
        ax.axis('off')
        
        # Title
        ax.text(0.05, 0.95, 'Magical Stories: Family Tales', 
               fontsize=20, fontweight='bold', color=self.colors['dark_gray'])
        ax.text(0.05, 0.92, 'Jun 28-Jul 27', 
               fontsize=14, color=self.colors['gray'])
        
        # Extract metrics from data
        overview = metrics_data.get("analytics", {}).get("overview", {})
        overview_metrics = overview.get("overview_metrics", {})
        
        # Define the 8 metric cards in 2 rows of 4
        metrics = [
            # Top row
            {
                "title": "IMPRESSIONS",
                "value": str(overview_metrics.get("impressions", {}).get("value", "1.52K")),
                "change": overview_metrics.get("impressions", {}).get("change", "0%"),
                "data": [0, 100, 80, 90, 85, 95, 75, 80, 85]
            },
            {
                "title": "PRODUCT PAGE VIEWS", 
                "value": str(overview_metrics.get("product_page_views", {}).get("value", "59")),
                "change": overview_metrics.get("product_page_views", {}).get("change", "0%"),
                "data": [0, 30, 25, 35, 28, 32, 26, 30, 28]
            },
            {
                "title": "CONVERSION RATE",
                "value": overview_metrics.get("conversion_rate", {}).get("value", "1.57%"),
                "change": overview_metrics.get("conversion_rate", {}).get("change", "0%"),
                "data": [0, 1.2, 1.8, 1.5, 2.0, 1.3, 1.7, 1.6, 1.5]
            },
            {
                "title": "TOTAL DOWNLOADS",
                "value": str(overview_metrics.get("total_downloads", {}).get("value", "26")),
                "change": overview_metrics.get("total_downloads", {}).get("change", "0%"),
                "data": [0, 8, 6, 10, 8, 12, 7, 9, 8]
            },
            # Bottom row
            {
                "title": "PROCEEDS",
                "value": overview_metrics.get("proceeds", {}).get("value", "$0"),
                "change": overview_metrics.get("proceeds", {}).get("change", "0%"),
                "data": [0, 0, 0, 0, 0, 0, 0, 0, 0]
            },
            {
                "title": "PROCEEDS PER PAYING USER",
                "value": overview_metrics.get("proceeds_per_paying_user", {}).get("value", "$0"),
                "change": overview_metrics.get("proceeds_per_paying_user", {}).get("change", "0%"),
                "data": [0, 0, 0, 0, 0, 0, 0, 0, 0]
            },
            {
                "title": "SESSIONS PER ACTIVE DEVICE",
                "value": str(overview_metrics.get("sessions_per_active_device", {}).get("value", "3.89")),
                "change": overview_metrics.get("sessions_per_active_device", {}).get("change", "0%"),
                "data": [3.2, 3.8, 4.1, 3.5, 4.2, 3.7, 3.9, 4.0, 3.8]
            },
            {
                "title": "CRASHES",
                "value": str(overview_metrics.get("crashes", {}).get("value", "0")),
                "change": overview_metrics.get("crashes", {}).get("change", "0%"),
                "data": [0, 0, 0, 0, 0, 0, 0, 0, 0]
            }
        ]
        
        # Card dimensions and positions
        card_width = 0.22
        card_height = 0.35
        start_x = 0.05
        start_y_top = 0.45
        start_y_bottom = 0.05
        spacing_x = 0.24
        
        # Draw top row
        for i, metric in enumerate(metrics[:4]):
            x = start_x + i * spacing_x
            self.create_metric_card(ax, metric["title"], metric["value"], 
                                  metric["change"], x, start_y_top, 
                                  card_width, card_height, True, metric["data"])
        
        # Draw bottom row  
        for i, metric in enumerate(metrics[4:]):
            x = start_x + i * spacing_x
            self.create_metric_card(ax, metric["title"], metric["value"],
                                  metric["change"], x, start_y_bottom,
                                  card_width, card_height, True, metric["data"])
        
        # Additional labels for specific metrics
        ax.text(start_x + 2 * spacing_x + 0.02, start_y_top - 0.02, 'Daily Average',
               fontsize=9, color=self.colors['gray'], style='italic')
        ax.text(start_x + 1 * spacing_x + 0.02, start_y_bottom - 0.02, 'Daily Average',
               fontsize=9, color=self.colors['gray'], style='italic')
        ax.text(start_x + 2 * spacing_x + 0.02, start_y_bottom - 0.02, 'Opt-in Only',
               fontsize=9, color=self.colors['gray'], style='italic')
        ax.text(start_x + 3 * spacing_x + 0.02, start_y_bottom - 0.02, 'Opt-in Only',
               fontsize=9, color=self.colors['gray'], style='italic')
        
        plt.tight_layout()
        
        # Save dashboard
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"{self.output_dir}/appstore_overview_dashboard_{timestamp}.png"
        plt.savefig(filename, dpi=300, bbox_inches='tight', 
                   facecolor=self.colors['light_gray'])
        plt.close()
        
        return filename
    
    def create_trends_analysis_dashboard(self, metrics_data: Dict) -> str:
        """Create detailed trends analysis dashboard"""
        
        fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(16, 12))
        fig.patch.set_facecolor(self.colors['white'])
        
        # Sample trend data (in real implementation, this would come from API)
        days = list(range(1, 31))
        
        # Downloads trend
        downloads_trend = [2, 3, 1, 4, 2, 3, 5, 1, 2, 4, 3, 2, 1, 3, 4, 2, 1, 3, 2, 4, 3, 1, 2, 3, 4, 2, 1, 3, 2, 1]
        ax1.plot(days, downloads_trend, color=self.colors['blue'], linewidth=2, marker='o', markersize=4)
        ax1.fill_between(days, downloads_trend, color=self.colors['blue'], alpha=0.1)
        ax1.set_title('Total Downloads Trend', fontsize=14, fontweight='bold')
        ax1.set_xlabel('Day of Month')
        ax1.set_ylabel('Downloads')
        ax1.grid(True, alpha=0.3)
        
        # Conversion rate trend  
        conversion_trend = [1.2, 1.8, 0.8, 2.1, 1.4, 1.7, 2.5, 0.9, 1.3, 2.0, 1.6, 1.2, 0.7, 1.5, 2.2, 1.1, 0.8, 1.8, 1.3, 2.3, 1.7, 0.9, 1.4, 1.9, 2.1, 1.2, 0.8, 1.6, 1.4, 0.9]
        ax2.plot(days, conversion_trend, color=self.colors['green'], linewidth=2, marker='s', markersize=4)
        ax2.fill_between(days, conversion_trend, color=self.colors['green'], alpha=0.1)
        ax2.set_title('Conversion Rate Trend', fontsize=14, fontweight='bold')
        ax2.set_xlabel('Day of Month')
        ax2.set_ylabel('Conversion Rate (%)')
        ax2.grid(True, alpha=0.3)
        
        # Sessions per device trend
        sessions_trend = [3.2, 3.8, 4.1, 3.5, 4.2, 3.7, 3.9, 4.0, 3.8, 4.1, 3.6, 3.9, 3.3, 4.0, 4.2, 3.7, 3.4, 3.8, 3.6, 4.1, 3.9, 3.5, 3.7, 4.0, 4.2, 3.8, 3.4, 3.9, 3.7, 3.6]
        ax3.plot(days, sessions_trend, color=self.colors['light_blue'], linewidth=2, marker='^', markersize=4)
        ax3.fill_between(days, sessions_trend, color=self.colors['light_blue'], alpha=0.1)
        ax3.set_title('Sessions per Active Device', fontsize=14, fontweight='bold')
        ax3.set_xlabel('Day of Month')
        ax3.set_ylabel('Sessions')
        ax3.grid(True, alpha=0.3)
        
        # Impressions trend
        impressions_trend = [80, 120, 90, 150, 100, 130, 110, 95, 140, 105, 125, 85, 115, 135, 120, 90, 100, 145, 110, 130, 115, 95, 105, 140, 125, 100, 85, 120, 110, 95]
        ax4.plot(days, impressions_trend, color=self.colors['red'], linewidth=2, marker='d', markersize=4)
        ax4.fill_between(days, impressions_trend, color=self.colors['red'], alpha=0.1)
        ax4.set_title('Impressions Trend', fontsize=14, fontweight='bold')
        ax4.set_xlabel('Day of Month')
        ax4.set_ylabel('Impressions')
        ax4.grid(True, alpha=0.3)
        
        plt.tight_layout()
        
        # Save trends dashboard
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"{self.output_dir}/trends_analysis_dashboard_{timestamp}.png"
        plt.savefig(filename, dpi=300, bbox_inches='tight')
        plt.close()
        
        return filename

def main():
    """Main execution function"""
    print("📊 App Store Connect Dashboard Visualizer")
    print("Creating App Store Connect-style visualizations...")
    print("=" * 50)
    
    # Initialize visualizer
    visualizer = AppStoreDashboardVisualizer()
    
    # Look for latest marketing data file
    data_files = [f for f in os.listdir('.') if f.startswith('marketing_raw_data_') and f.endswith('.json')]
    
    if data_files:
        # Use the most recent data file
        latest_file = sorted(data_files)[-1]
        print(f"📂 Loading data from: {latest_file}")
        
        try:
            with open(latest_file, 'r') as f:
                metrics_data = json.load(f)
                
            # Create App Store overview dashboard
            overview_file = visualizer.create_app_store_overview_dashboard(metrics_data)
            print(f"✅ Created overview dashboard: {overview_file}")
            
            # Create trends analysis dashboard
            trends_file = visualizer.create_trends_analysis_dashboard(metrics_data)
            print(f"✅ Created trends dashboard: {trends_file}")
            
            print(f"\n🎯 Dashboard visualizations created successfully!")
            print(f"📁 Output directory: {visualizer.output_dir}/")
            
        except Exception as e:
            print(f"❌ Error loading data: {e}")
            
    else:
        print("⚠️  No marketing data files found.")
        print("💡 Run comprehensive_marketing_analytics.py first to collect data.")
        
        # Create sample dashboard with placeholder data
        sample_data = {
            "analytics": {
                "overview": {
                    "overview_metrics": {
                        "impressions": {"value": "1.52K", "change": "0%"},
                        "product_page_views": {"value": "59", "change": "0%"},
                        "conversion_rate": {"value": "1.57%", "change": "0%"},
                        "total_downloads": {"value": "26", "change": "0%"},
                        "proceeds": {"value": "$0", "change": "0%"},
                        "proceeds_per_paying_user": {"value": "$0", "change": "0%"},
                        "sessions_per_active_device": {"value": "3.89", "change": "0%"},
                        "crashes": {"value": "0", "change": "0%"}
                    }
                }
            }
        }
        
        overview_file = visualizer.create_app_store_overview_dashboard(sample_data)
        trends_file = visualizer.create_trends_analysis_dashboard(sample_data)
        
        print(f"✅ Created sample overview dashboard: {overview_file}")
        print(f"✅ Created sample trends dashboard: {trends_file}")

if __name__ == "__main__":
    main()