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
		 * override createChildren to create the StyleableTextfield control
		 */
		/*override protected function createChildren():void {
			super.createChildren();
			
			//make sure it does not already exist
			if (!labelDisplay) {
				dayLineDisplay = new StyleableTextField();
				
				//add the child as a child of the item renderer
				
				addChild(dayLineDisplay);
				label
			}
		}*/
		
		
		
		/**
		 * override the data property to initialize dayLineDisplay
		 */
		
		override public function set data(value:Object):void {
			super.data = value;
			labelDisplay.text = dateFormatter.format((value as DayLine).timeStamp);
		}
		
		override protected function createLabelDisplay():void {
			super.createLabelDisplay();
			
		}
		
		override protected function drawBackground(unscaledWidth:Number, unscaledHeight:Number):void {
			
		}
	}
}