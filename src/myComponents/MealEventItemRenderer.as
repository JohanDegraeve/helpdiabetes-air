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
	import databaseclasses.MealEvent;
	
	import flash.system.Capabilities;
	import flash.text.TextLineMetrics;
	
	import mx.collections.ArrayList;
	
	import spark.components.Application;
	import spark.components.IconItemRenderer;
	import spark.components.Label;
	import spark.components.LabelItemRenderer;
	import spark.components.supportClasses.StyleableTextField;
	
	/**
	 * an itemrenderer for a mealevent<br>
	 * What shall it show<br>
	 * - a timestamp (hh:mm) and mealname - the amount of carbs<br>
	 * - if  the mealevent is extended :<br>
	 * &nbsp;&nbsp;&nbsp;- the insulin ratio used to calculate the insulin amount if not 0, the correction factor if not zero, the calculated insulin amount<br>
	 * &nbsp;&nbsp;&nbsp;- all the selected meals one by one<br>
	 * <br>
	 * When is a mealevent extended ?<br>
	 * if the allMealsExtended flag is true, then all mealeventss are extended<br>
	 * if allMealsExtended flag is false, then only the mealevent with id ModellOcator.selectedMeal
	 */
	public class MealEventItemRenderer extends LabelItemRenderer
	{
		//*****************//
		// the display fields //
		// labelDisplay will be used to shown the first field with timestamp and meal name on the left and amount on the right
		/**
		 * the calculated amount of carbs
		 */
		private var carbAmountDisplay:StyleableTextField;
		
		/**
		 * the carbamount
		 */
		private var _carbAmount:String;

		private function get carbAmount():String
		{
			return _carbAmount;
		}

		private function set carbAmount(value:String):void
		{
			if (value == _carbAmount)
				return;
				
			_carbAmount = value;
			if (carbAmountDisplay) {
				carbAmountDisplay.text = _carbAmount;
				invalidateSize();
			}
		}

		
		/**
		 * the second line, optional, with insulin ratio, insulin amount, cf
		 */
		private var insulinField:StyleableTextField;
		/**
		 * arraylist of styleabletextfields with the selected meals
		 */
		private var selectedMeals:ArrayList;
		
		//*****************//
		/**
		 * if true then all mealevents are shown extended<br>
		 */
		private var allMealsExtended:Boolean = false;
		
		/**
		 * padding left 
		 */
		private static const PADDING_LEFT:int = 5;
		/**
		 * padding right 
		 */
		private static const PADDING_RIGHT:int = 5;
		/**
		 * padding top for item
		 */
		private static const PADDING_TOP:int=5;
		/**
		 * minimum gap between two elements, horizontal
		 */
		private static const GAP_HORIZONTAL_MINIMUM:int = 5;
		
		/**
		 * this is the width we would minimally need to represent 3 digits + 3 dots, because that's I assume the maximum number of digits we'll need to represent 
		 * the amount value.<br>
		 * Ideally this value should be calculated somewhere, eg based on style, calculate size for 3 times the largest digit + 3 dots<br>
		 * this is done in createchildren but seems not fully correct
		 */
		private var MINIMUM_CARB_AMOUNT_WIDTH:int = 100;

		/**
		 * default constructor 
		 */
		public function MealEventItemRenderer()
		{
			super();
		}

		/**
		 * override the data property to initialize MealEventItemRenderer<br>
		 * value needs to be a mealevent
		 */
		override public function set data(value:Object):void {
			super.data = value;
			
			if (!data) return;//did this because I found it in an example 
			
			var date:Date = new Date(((value as MealEvent).timeStamp));
			label = 
				(date.hours.toString().length == 1 ? "0":"") + 	date.hours 
				+ ":"  
				+ (date.minutes.toString().length == 1 ? "0":"") + date.minutes 
				+ " " 
				+ (value as MealEvent).mealName;

				carbAmount = Math.round((value as MealEvent).totalCarbs).toString();
		}
		
		/**
		 * adds my own components
		 */
		override protected function createChildren():void {
			super.createChildren();
			
			if (!carbAmountDisplay) {
				carbAmountDisplay = new StyleableTextField();
				carbAmountDisplay.styleName = this;
				carbAmountDisplay.editable = false;
				carbAmountDisplay.multiline = false;
				carbAmountDisplay.wordWrap = false;
				addChild(carbAmountDisplay);
			}

			// calculate MINIMUM_CARB_AMOUNT_WIDTH
			var textLineMetricx:TextLineMetrics = this.measureText("9999 ...");
			MINIMUM_CARB_AMOUNT_WIDTH = textLineMetricx.width;
		}
		
		// Override styleChanged() to proopgate style changes to compLabelDisplay.
		override public function styleChanged(styleName:String):void {
			super.styleChanged(styleName);
			
			// Pass any style changes to compLabelDisplay. 
			if (carbAmountDisplay)
				carbAmountDisplay.styleChanged(styleName);
		}
		
		/*// Override measure() to calculate the size required by the item renderer.
		override protected function measure():void {
			super.measure();
				
			// Commit the styles changes to labelDisplay and carbAmount. 
			// This method must be called before the text is displayed, 
			// and any time the styles have changed. 
			// This method does nothing if the styles have already been committed. 
			labelDisplay.commitStyles();
			
			if (carbAmountDisplay) {
				if (carbAmountDisplay.isTruncated)
					carbAmountDisplay.text = carbAmount;
				carbAmountDisplay.commitStyles();
				measuredWidth = PADDING_LEFT + getElementPreferredWidth(labelDisplay) + GAP_HORIZONTAL_MINIMUM +  getElementPreferredWidth(carbAmountDisplay) + PADDING_RIGHT;
				measuredHeight = Math.max(getElementPreferredHeight(labelDisplay), getElementPreferredHeight(carbAmountDisplay)) + PADDING_TOP; 
			}
		}*/
		
		
		// Override layoutContents() to lay out the item renderer.
		override protected function layoutContents(unscaledWidth:Number, unscaledHeight:Number):void {
			// Because you are handling the layout of both the 
			// predefined labelDisplay component and the new 
			// carbAmount component, you do not have to call
			// super.layoutContents().
			
			// Commit the styles changes to labelDisplay and compLabelDisplay. 
			labelDisplay.commitStyles();
			carbAmountDisplay.commitStyles();
			
			//carbamount should have a minimum displaylength - labeldisplay will be shortened if needed
			//and then we'll extend carbamount if still possible
			var carbAmountDisplayWidth:Number = Math.max(getElementPreferredWidth(carbAmountDisplay), MINIMUM_CARB_AMOUNT_WIDTH);
			var labelDisplayWidth:Number = Math.min(getElementPreferredWidth(labelDisplay),unscaledWidth - PADDING_LEFT - PADDING_RIGHT - carbAmountDisplayWidth);
			carbAmountDisplay.text = carbAmount + " " + resourceManager.getString('general','gram_of_carbs_short');
			carbAmountDisplayWidth = Math.min(unscaledWidth - PADDING_LEFT - labelDisplayWidth - GAP_HORIZONTAL_MINIMUM - PADDING_RIGHT, getElementPreferredWidth(carbAmountDisplay));
			
			var carbAmountDisplayHeight:Number = getElementPreferredHeight(carbAmountDisplay);
			var labelDisplayHeight:Number = getElementPreferredHeight(labelDisplay);

			
			/*if (carbAmount != null) {
				carbAmountDisplay.commitStyles();
				if (carbAmountDisplay.isTruncated)
					carbAmountDisplay.text == carbAmount;
				carbAmountDisplayHeight = ;
			}*/
			setElementSize(labelDisplay,labelDisplayWidth,labelDisplayHeight);
			setElementSize(carbAmountDisplay,carbAmountDisplayWidth,carbAmountDisplayHeight);
			labelDisplay.truncateToFit();
			carbAmountDisplay.truncateToFit();
			
			setElementPosition(labelDisplay,0 + PADDING_LEFT,PADDING_TOP);
			setElementPosition(carbAmountDisplay,unscaledWidth - PADDING_RIGHT - carbAmountDisplayWidth,PADDING_TOP);
		}
	}
}