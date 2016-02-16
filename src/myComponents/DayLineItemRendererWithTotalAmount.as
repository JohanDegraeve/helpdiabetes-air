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
	import databaseclasses.MealEvent;
	import databaseclasses.Settings;
	
	import flash.text.TextLineMetrics;
	
	import model.ModelLocator;
	
	import spark.components.supportClasses.StyleableTextField;

	/**
	 * an extension of daylineitemrender, that shows the total amount per day, of carbs or kilocalories or fat or protein - setting dependent 
	 */
	public class DayLineItemRendererWithTotalAmount extends DayLineItemRenderer 
	{
		private var itemHeight:int = styleManager.getStyleDeclaration(".trackingItems").getStyle("trackingeventHeight");
		private var offsetToPutTextInTheMiddle:int = styleManager.getStyleDeclaration(".trackingItems").getStyle("offsetToPutTextInTheMiddle");
		
		/**
		 * total amount for the day of carbs, protein, kilocalories or fat, depending on the user's preference
		 */
		private var _totalAmount:String="0";
		
		private function get totalAmount():String
		{
			return _totalAmount;
		}

		private function set totalAmount(value:String):void
		{
			if (value == _totalAmount)
				return;
			
			_totalAmount = value;
			if (carbAmountDisplay) {
				carbAmountDisplay.text = Math.round(new Number(_totalAmount)).toString();
				invalidateSize();
			}
		}

		/**
		 * padding left 
		 */
		private static const PADDING_LEFT:int = 15;
		/**
		 * padding right 
		 */
		private static const PADDING_RIGHT:int = 15;
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
		private var MINIMUM_AMOUNT_WIDTH:int = 100;
		
		/**
		 * the calculated amount for the day
		 */
		private var carbAmountDisplay:StyleableTextField;
		
		/**
		 * constructor 
		 */
		public function DayLineItemRendererWithTotalAmount()
		{
			super();
		}
		
		// Override measure() to calculate the size required by the item renderer.
		override protected function measure():void {
			measuredHeight = getHeight();
			measuredMinHeight = measuredHeight;
		}
		
		/**
		 * override the data property to initialize dayLineDisplay
		 */
		override public function set data(value:Object):void {
			super.data = value;
			
			if (!data) return;
			
			var endOfDay:Number = (value as DayLine).timeStamp + (86400000 - 1);
			var totalAmountAsNumber:Number = 0;
			var foundAMealEventInTheSameDay:Boolean = false;
			for (var i:int = ModelLocator.trackingList.length - 1;i >= 0 ;i--) {
				if (ModelLocator.trackingList.getItemAt(i) is MealEvent) 
					if ((ModelLocator.trackingList.getItemAt(i) as MealEvent).timeStamp >= (value as DayLine).timeStamp) { 
						if ((ModelLocator.trackingList.getItemAt(i) as MealEvent).timeStamp < endOfDay) {
							foundAMealEventInTheSameDay = true;
							if (Settings.getInstance().getSetting(Settings.SettingsIMPORTANT_VALUE_FOR_USER) == "carbs") 
								totalAmountAsNumber = totalAmountAsNumber + (ModelLocator.trackingList.getItemAt(i) as MealEvent).totalCarbs;
							else
								if (Settings.getInstance().getSetting(Settings.SettingsIMPORTANT_VALUE_FOR_USER) == "protein")
									totalAmountAsNumber = totalAmountAsNumber + (ModelLocator.trackingList.getItemAt(i) as MealEvent).totalProtein;
								else
									if (Settings.getInstance().getSetting(Settings.SettingsIMPORTANT_VALUE_FOR_USER) == "fat")
										totalAmountAsNumber = totalAmountAsNumber + (ModelLocator.trackingList.getItemAt(i) as MealEvent).totalFat;
									else
										if (Settings.getInstance().getSetting(Settings.SettingsIMPORTANT_VALUE_FOR_USER) == "kilocalories")
											totalAmountAsNumber = totalAmountAsNumber + (ModelLocator.trackingList.getItemAt(i) as MealEvent).totalKilocalories;
						} else {
							if (foundAMealEventInTheSameDay) //stop searching
								i = -1;
						}
					} else {
						if (foundAMealEventInTheSameDay) //stop searching
							i = -1;
					}
			totalAmount = totalAmountAsNumber.toString();
			}
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
			if (MINIMUM_AMOUNT_WIDTH == 0) {
				// calculate MINIMUM_CARB_AMOUNT_WIDTH
				var textLineMetricx:TextLineMetrics = this.measureText("999 ...");
				MINIMUM_AMOUNT_WIDTH = textLineMetricx.width;
			}
		}
		
		// Override styleChanged() to proopgate style changes to compLabelDisplay.
		override public function styleChanged(styleName:String):void {
			super.styleChanged(styleName);
			
			// Pass any style changes to compLabelDisplay. 
			if (carbAmountDisplay)
				carbAmountDisplay.styleChanged(styleName);
		}
		
		// Override layoutContents() to lay out the item renderer.
		override protected function layoutContents(unscaledWidth:Number, unscaledHeight:Number):void {
			var carbAmountDisplayWidth:Number = Math.max(getElementPreferredWidth(carbAmountDisplay), MINIMUM_AMOUNT_WIDTH);
			var labelDisplayWidth:Number = Math.min(getElementPreferredWidth(labelDisplay),unscaledWidth - PADDING_LEFT - PADDING_RIGHT - carbAmountDisplayWidth);
			
			carbAmountDisplay.text = Math.round(new Number(totalAmount)) + " " + resourceManager.getString('general','gram_of_carbs_short');
			carbAmountDisplayWidth = Math.min(unscaledWidth - PADDING_LEFT - labelDisplayWidth - GAP_HORIZONTAL_MINIMUM - PADDING_RIGHT, getElementPreferredWidth(carbAmountDisplay));

			setElementSize(labelDisplay,labelDisplayWidth,itemHeight);
			setElementSize(carbAmountDisplay,carbAmountDisplayWidth,itemHeight);
			
			labelDisplay.truncateToFit();
			carbAmountDisplay.truncateToFit();
			
			setElementPosition(labelDisplay,0 + PADDING_LEFT,offsetToPutTextInTheMiddle);
			setElementPosition(carbAmountDisplay,unscaledWidth - PADDING_RIGHT - carbAmountDisplayWidth,offsetToPutTextInTheMiddle);
		}
		
		override public function getHeight(item:TrackingViewElement = null):Number {
			//if item = null then assign item to data, which may be (not sure yet) a mealevent
			//wheter it's a mealevent or not is checked by checking later against null value, if not null then it must be a mealevent
			if (item == null)
				item = (this.data as DayLineWithTotalAmount);
			if (item == null) //parameter was null and this.data is also null, so there's nothing to calculate
				return 0;
			
			return itemHeight ;
		}

	}
}