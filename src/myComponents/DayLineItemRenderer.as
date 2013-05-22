/**
 Copyright (C) 2013  hippoandfriends
 
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
	
	import flash.system.Capabilities;
	
	import spark.formatters.DateTimeFormatter;

	public class DayLineItemRenderer extends TrackingViewElementItemRenderer
	{
		/**
		 * to display the date 
		 */
		//not necessary because it already has a styleabletextfield named labeldisplay -- private var dayLineDisplay:StyleableTextField;
		
		private static var dateFormatter:DateTimeFormatter ;
		
		public function DayLineItemRenderer()
		{
			super();
			if (dateFormatter == null) {
				dateFormatter = new DateTimeFormatter();
				dateFormatter.dateTimePattern = resourceManager.getString('general','datepattern');
				dateFormatter.useUTC = false;
				dateFormatter.setStyle("locale",Capabilities.language.substr(0,2));
			}
			setStyle("color","white");
			setStyle("textAlign","center");
		}
		
		/**
		 * override the data property to initialize dayLineDisplay
		 */
		override public function set data(value:Object):void {
			super.data = value;
			label= dateFormatter.format((value as DayLine).timeStamp);
		}
		
		/**
		 * Draw a blue background depending of it's sunday or weekday
		 */
		override protected function drawBackground(unscaledWidth:Number, unscaledHeight:Number):void
		{
			graphics.beginFill(0x213A5C, 1);
			graphics.drawRect(0, 0, unscaledWidth, unscaledHeight);
			graphics.endFill();

			//super.drawBackground(unscaledWidth,unscaledHeight);//to make the clicked items visible
		}
	}
}