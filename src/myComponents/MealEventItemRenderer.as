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
	
	import views.TemplatesView;
	
	/**
	 * an itemrenderer for a mealevent<br>
	 * What shall it show<br>
	 * - a timestamp (hh:mm) and mealname - the amount of carbs, protein, fat or kilocalories, depending on user preferences<br>
	 * - if  the mealevent is extended :<br>
	 * &nbsp;&nbsp;&nbsp;- the insulin ratio used to calculate the insulin amount if not 0, the correction factor if not zero, the calculated insulin amount<br>
	 * &nbsp;&nbsp;&nbsp;- all the selected meals one by one<br>
	 * <br>
	 * When is a mealevent extended ?<br>
	 * if the allMealsExtended flag is true, then all mealevents are extended<br>
	 * if allMealsExtended flag is false, then only the mealevent with id ModelLocator.selectedMeal
	 */
	public class MealEventItemRenderer extends LabelItemRenderer
	{
		//*****************//
		// the display fields //
		// labelDisplay will be used to shown the first field with timestamp and meal name on the left and amount on the right
		/**
		 * the field for the calculated amount of carbs - will be put on the right side of the first line, 
		 */
		private var carbAmountDisplay:StyleableTextField;
		
		/**
		 * the carbamount in string
		 */
		private var _carbAmount:String;

		private function get carbAmount():String
		{
			return _carbAmount;
		}

		/**
		 * sets _carbAmount, if carbAmountDisplay not null then also invalidateSize() is called
		 */
		private function set carbAmount(value:String):void
		{
			if (value == _carbAmount)
				return;
				
			_carbAmount = value;
			if (carbAmountDisplay != null) {
				carbAmountDisplay.text = _carbAmount;
				invalidateSize();
			}
		}

		/**
		 * styleabletextfield with the calculated insulinamount, selected food elements and all the rest<br>
		 */
		private var otherDetails:StyleableTextField;
		
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
		 * override the data property to initialize MealEventItemRenderer fields<br>
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
			
			if (!otherDetails) {
				otherDetails = new StyleableTextField();
				otherDetails.styleName = this;
				otherDetails.editable = false;
				otherDetails.multiline = false;//i find it strange, text is longer than one line, but it works even with multiline and wordwrap equal to false
				otherDetails.wordWrap = false;
				otherDetails.setStyle("fontSize",styleManager.getStyleDeclaration(".fontSizeForSubElements").getStyle("fontSize"));//other details is written a bit smaller, fontsize defined in style.css
				addChild(otherDetails);
			}
		}
		
		// Override styleChanged() to proopgate style changes to compLabelDisplay.
		override public function styleChanged(styleName:String):void {
			super.styleChanged(styleName);
			
			// Pass any style changes to compLabelDisplay. 
			if (carbAmountDisplay)
				carbAmountDisplay.styleChanged(styleName);
			if (otherDetails)
				otherDetails.styleChanged(styleName);
		}
		
		// Override measure() to calculate the size required by the item renderer.
		override protected function measure():void {
			super.measure();
				
			// Commit the styles changes to labelDisplay and carbAmount. 
			// This method must be called before the text is displayed, 
			// and any time the styles have changed. 
			// This method does nothing if the styles have already been committed. 
			labelDisplay.commitStyles();
			carbAmountDisplay.commitStyles();
			if (otherDetails)
				otherDetails.commitStyles();

			//the needed height = sum of hights of different text fields + paddings..
			measuredHeight = 
				/* the height needed for the first line */ labelDisplay.textHeight + getStyle("paddingTop") +  getStyle("paddingBottom") + 
				/* hight needed for other details field */ (otherDetails == null ? 0:otherDetails.textHeight);
		}
		
		// Override layoutContents() to lay out the item renderer.
		override protected function layoutContents(unscaledWidth:Number, unscaledHeight:Number):void {
			// Because you are handling the layout of both the 
			// predefined labelDisplay component and the new 
			// carbAmount component, you do not have to call
			// super.layoutContents().
			
			// Commit the styles changes to labelDisplay and compLabelDisplay and others
			labelDisplay.commitStyles();
			carbAmountDisplay.commitStyles();
			if (otherDetails)
				otherDetails.commitStyles();
			
			//carbamount should have a minimum displaylength - labeldisplay will be shortened if needed
			//and then we'll extend carbamount if still possible
			var carbAmountDisplayWidth:Number = Math.max(getElementPreferredWidth(carbAmountDisplay), MINIMUM_CARB_AMOUNT_WIDTH);
			var labelDisplayWidth:Number = Math.min(getElementPreferredWidth(labelDisplay),unscaledWidth - PADDING_LEFT - PADDING_RIGHT - carbAmountDisplayWidth);
			carbAmountDisplay.text = carbAmount + " " + resourceManager.getString('general','gram_of_carbs_short');
			carbAmountDisplayWidth = Math.min(unscaledWidth - PADDING_LEFT - labelDisplayWidth - GAP_HORIZONTAL_MINIMUM - PADDING_RIGHT, getElementPreferredWidth(carbAmountDisplay));
			
			var carbAmountDisplayHeight:Number = getElementPreferredHeight(carbAmountDisplay);
			var labelDisplayHeight:Number = getElementPreferredHeight(labelDisplay);
			
			setElementSize(labelDisplay,labelDisplayWidth,labelDisplayHeight);
			setElementSize(carbAmountDisplay,carbAmountDisplayWidth,carbAmountDisplayHeight);
			labelDisplay.truncateToFit();
			carbAmountDisplay.truncateToFit();
			
			setElementPosition(labelDisplay,0 + PADDING_LEFT,getStyle("paddingTop"));
			setElementPosition(carbAmountDisplay,unscaledWidth - PADDING_RIGHT - carbAmountDisplayWidth,getStyle("paddingTop"));
			
		    otherDetails.text = "qldkfjqlksjfldksjf mqlsjdf  \nqmljsdf q qdfgqdfgqdsgdfsfm q s i i i   fdsj i i i i i i i i i i i qshjdkf qsldkfjl mqsfmlkqsdjflkm qsdjmlkf dsfeinde tweede lijn\nqsdfdsqfdqsfdsf\neinde ";//resourceManager.getString('general','calculated_insulin_amount');
			setElementSize(otherDetails,unscaledWidth - PADDING_RIGHT - PADDING_LEFT,getElementPreferredHeight(otherDetails));
			setElementPosition(otherDetails,0 + PADDING_LEFT,labelDisplayHeight + getStyle("paddingTop") + styleManager.getStyleDeclaration(".fontSizeForSubElements").getStyle("fontSize"));
			invalidateSize();
		}
	}
}