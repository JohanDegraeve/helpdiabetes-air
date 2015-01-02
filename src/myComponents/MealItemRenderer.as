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
	
	import databaseclasses.Meal;
	import spark.components.LabelItemRenderer;
	
	public class MealItemRenderer extends LabelItemRenderer
	{
		/**
		 * to display the date 
		 */
		//not necessary because it already has a styleabletextfield named labeldisplay -- private var dayLineDisplay:StyleableTextField;
		
		public function MealItemRenderer()
		{
			super();
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
			labelDisplay.text = (value as Meal).mealName;
		}
		
		override protected function drawBackground(unscaledWidth:Number, unscaledHeight:Number):void
		{
			//only draw a border line
			graphics.lineStyle(1, 0, 0.75);
			graphics.moveTo(0,unscaledHeight - 1);
			graphics.lineTo(unscaledWidth,unscaledHeight - 1);
			graphics.endFill();
			if (down) {
				graphics.beginFill(0, 0.25);
				graphics.drawRect(0, 0, unscaledWidth, unscaledHeight);
				graphics.endFill();
			}
		}

	}
}