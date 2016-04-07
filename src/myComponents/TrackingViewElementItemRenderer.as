/**
 Copyright (C) 2016  hippoandfriends
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/gpl.txt>.
 
 */
package myComponents
{
	import spark.components.LabelItemRenderer;
	import databaseclasses.Settings;
	import model.ModelLocator;

	/**
	 * a superclass for the itemrenderers that are used for elements that can be in a trackingview<br>
	 * the goal is that the real itemrenderers extend from TrackingViewElementItemRenderer and override getHeight and getWidth and calculate the 
	 * height and width for the parameter item.<br>
	 */
	public class TrackingViewElementItemRenderer extends LabelItemRenderer
	{
		
		public function TrackingViewElementItemRenderer() 
		{
		}
		
		/**
		 * the goal is that the real itemrenderers extend from TrackingViewElementItemRenderer and overrides getHeight calculate the 
		 * height and width for the parameter item.<br>
		 * if Item is null, then the implementation should try to calculate the height for the own data property<br>
		 */
		public function getHeight(item:TrackingViewElement = null):Number {
			return 0;				
		}
		
		override protected function drawBackground(unscaledWidth:Number, unscaledHeight:Number):void
		{
			//only draw a border line
			graphics.lineStyle(1, 0, 0.75);
			graphics.moveTo(0,unscaledHeight - 1);
			graphics.lineTo(unscaledWidth,unscaledHeight - 1);
			graphics.endFill();
			
			if ((data as TrackingViewElement).mark) {
				graphics.beginFill(0xC0EDFF, 0.75);
				graphics.drawRect(0, 0, unscaledWidth, unscaledHeight);
				graphics.endFill();
				if ((data as TrackingViewElement).eventid == ModelLocator.trackingEventToShow) {
					graphics.lineStyle(unscaledHeight/20, 0xFF0000, 0.5);
					graphics.lineTo(0, unscaledHeight);
					graphics.lineTo(unscaledWidth,unscaledHeight);
					graphics.lineTo(unscaledWidth,0);
					graphics.lineTo(0,0);
					graphics.endFill();
				}
			} else {
				var creationTimeStampAsDate:Date = new Date((data as TrackingViewElement).timeStamp);
				var temp:Date = (new Date(creationTimeStampAsDate.fullYearUTC,creationTimeStampAsDate.monthUTC,creationTimeStampAsDate.dateUTC,0,0,0,0));
				var creationTimeStampAsNumber:Number = creationTimeStampAsDate.valueOf() - temp.valueOf();
				if (creationTimeStampAsNumber < new Number(Settings.getInstance().getSetting(Settings.SettingBREAKFAST_UNTIL)))
					;
				else if (creationTimeStampAsNumber < new Number(Settings.getInstance().getSetting(Settings.SettingSNACK_UNTIL))) {
					graphics.beginFill(0xF0D1DE,0.5);
					graphics.drawRect(0, 0, unscaledWidth, unscaledHeight);
					graphics.endFill();
				}
			}
			
			if (down) {
				graphics.beginFill(0, 0.25);
				graphics.drawRect(0, 0, unscaledWidth, unscaledHeight);
				graphics.endFill();
			}
		}
	}
}