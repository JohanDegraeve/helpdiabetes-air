/**
 Copyright (C) 2011  hippoandfriends
 
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
	
	import flash.display.GradientType;
	import flash.geom.Matrix;
	import flash.globalization.LocaleID;
	import flash.system.Capabilities;
	
	import mx.formatters.DateFormatter;
	import mx.states.AddChild;
	
	import spark.components.LabelItemRenderer;
	import spark.components.supportClasses.StyleableTextField;
	import spark.formatters.DateTimeFormatter;

	public class DayLineItemRenderer extends LabelItemRenderer
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
		}
		
		/**
		 * override the data property to initialize dayLineDisplay
		 */
		override public function set data(value:Object):void {
			super.data = value;
			labelDisplay.text = dateFormatter.format((value as DayLine).timeStamp);
		}
		
		/**
		 * Draw a blue background depending of it's sunday or weekday
		 */
		override protected function drawBackground(unscaledWidth:Number, unscaledHeight:Number):void
		{
			var darkBlueLight:* = styleManager.getStyleDeclaration(".backGroundColorInLists").getStyle("darkBlueLight");
			var darkBlueDark:* = styleManager.getStyleDeclaration(".backGroundColorInLists").getStyle("darkBlueDark");
			var lightBlueLight:* = styleManager.getStyleDeclaration(".backGroundColorInLists").getStyle("lightBlueLight");
			var lightBlueDark:* = styleManager.getStyleDeclaration(".backGroundColorInLists").getStyle("lightBlueDark");
			
			var darkBackGroundColors:Array = [darkBlueDark, darkBlueLight];
			var lightBackGroundColors:Array = [lightBlueDark, lightBlueLight];
			var alphas:Array = [1, 1];
			var ratios:Array = [0, 255];
			var matrix:Matrix = new Matrix();
			
			// draw the heading gradient first
			matrix.createGradientBox(unscaledWidth, unscaledHeight, Math.PI / 2, 0, 0);
			graphics.beginGradientFill(GradientType.LINEAR, lightBackGroundColors, alphas, ratios, matrix);
			graphics.drawRect(0, 0, unscaledWidth, unscaledHeight);
			graphics.endFill();
		}

		
	}
}