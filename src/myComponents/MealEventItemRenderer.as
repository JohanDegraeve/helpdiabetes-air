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
	import databaseclasses.SelectedFoodItem;
	
	import flash.display.GradientType;
	import flash.geom.Matrix;
	import flash.system.Capabilities;
	import flash.text.AntiAliasType;
	import flash.text.TextLineMetrics;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ArrayList;
	
	import spark.components.Application;
	import spark.components.IconItemRenderer;
	import spark.components.Label;
	import spark.components.LabelItemRenderer;
	import spark.components.supportClasses.StyleableTextField;
	
	import views.SelectMealView;
	import views.TemplatesView;
	
	/**
	 * an itemrenderer for a mealevent<br>
	 * What shall it show<br>
	 * - a timestamp (hh:mm) and mealname - the amount of carbs, protein, fat or kilocalories, depending on user preferences<br>
	 * - the calculated insulin amount, if the insulin ratio used to calculate the insulin amount if not 0<br>
	 * - if  the mealevent is extended :<br>
	 * &nbsp;&nbsp;&nbsp;- all the selected meals one by one<br>
	 * <br>
	 * When is a mealevent extended ?<br>
	 * if the allMealsExtended flag is true, then all mealevents are extended<br>
	 * if allMealsExtended flag is false, then only the mealevent with id ModelLocator.selectedMeal
	 */
	public class MealEventItemRenderer extends TrackingViewElementItemRenderer
	{
		//*****************//
		// the display fields //
		// labelDisplay will be used to shown the first field with timestamp and meal name on the left and amount on the right
		/**
		 * the field for the calculated amount of carbs - will be put on the right side of the first line, 
		 */
		private var carbAmountDisplay:StyleableTextField;
		
		/**
		 * the field for the calculated insulinAmount 
		 */
		private var insulinAmountDisplay:StyleableTextField;
		
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
		 * the insulinAmount as string
		 */
		private var _insulinAmount:String;
		/**
		 * get the insulinAmount 
		 */
		private function get insulinAmount():String
		{
			return _insulinAmount;
		}
		
		/**
		 * sets _insulinAmount, if insulinAmountDisplay not null then also invalidateSize() is called
		 */
		private function set insulinAmount(value:String):void
		{
			if (value == _insulinAmount)
				return;
			
			_insulinAmount = value;
			if (insulinAmountDisplay != null) {
				insulinAmountDisplay.text = _insulinAmount;
				invalidateSize();
			}
		}
		
		
		/**
		 * the fooditem descriptions + amount + unit of the the selectedmeals<br>
		 * One item in the arraycollection per selected item<br>
		 * the Arraycollection will hold strings.  
		 */
		private var selectedMealsDescriptionStrings:ArrayCollection;
		/**
		 * the carbamounts of the the selectedmeals<br>
		 * One item in the arraycollection per selected item<br>
		 * the Arraycollection will hold strings.  
		 */
		private var selectedMealsCarbAmountStrings:ArrayCollection;
		/**
		 * styleabletextfield with the calculated insulinamount<br>
		 */
		private var insulinDetails:StyleableTextField;
		
		/**
		 *  styleabletextfield for showing the selectedMealsDescriptionStrings
		 */
		private var selectedMealsDescriptionStyleableTextFields:ArrayCollection;
		/**
		 *  styleabletextfield for showing the selectedMealsCarbAmountStrings
		 */
		private var selectedMealsCarbAmountStyleableTextFields:ArrayCollection;
		
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
		 * helper variable 
		 */
		private var gramkh:String;
		
		/**
		 * this is the width we would minimally need to represent 3 digits + 3 dots, because that's I assume the maximum number of digits we'll need to represent 
		 * the amount value.<br>
		 * Ideally this value should be calculated somewhere, eg based on style, calculate size for 3 times the largest digit + 3 dots<br>
		 * this is done in createchildren but seems not fully correct<br>
		 * This is for the norma fontsize
		 */
		static private var MINIMUM_CARB_AMOUNT_WIDTH_LARGE_FONT:int = 100;
		/**
		 * this is the width we would minimally need to represent 3 digits + 3 dots, because that's I assume the maximum number of digits we'll need to represent 
		 * the amount value.<br>
		 * Ideally this value should be calculated somewhere, eg based on style, calculate size for 3 times the largest digit + 3 dots<br>
		 * this is done in createchildren but seems not fully correct<br>
		 * this is for the sub font size (or small font size)
		 */
		static private var MINIMUM_CARB_AMOUNT_WIDTH_SMALL_FONT:int=100;

		//all variables to maintain previous heights, if changed then invalidatesize must be called.
		private var previousY:Number = 0;
		
		//variables to calculate the width and height of a mealevent rendered with this renderer
		//preferred values are values obtained with method getPreferredHeight
		//calculated values are values obtained with object-name.height
		//preferred values needs to be used in  method setelementsize
		//calculated values needs to be used to calculate the real heigh, eg val calculating currentY
		private static var _carbAmountCalculatedHeight:Number = 0;
		private static var _carbAmountPreferredHeight:Number = 0;
		private static var _insulinAmountCalculatedHeight:Number = 0;
		private static var _insulinAmountPreferredHeight:Number = 0;
		private static var _selectedMealCalculatedHeight:Number = 0;
		private static var _selectedMealPreferredHeight:Number = 0;
		
		private static var theMiddleOfCarbAmountField:Number = 0;
		private static var theMiddleOfSelectedItemField:Number = 0;
		private static var theMiddleOfInsulinField:Number = 0;
		
		/**
		 * if styleabletextfield is added, then paddingbottom is too high, next element will be uplifted by an amount of pixels which is upLiftForNextField.
		 */
		private static var upLiftForNextField:int;
		
		/**
		 * default constructor <br>
		 * calls super and sets insulinAmount to null<br>
		 */
		public function MealEventItemRenderer()
		{
			super();
			insulinAmount = null;
			gramkh = resourceManager.getString('general','gram_of_carbs_short');
			if (upLiftForNextField == 0)
				upLiftForNextField = styleManager.getStyleDeclaration(".removePaddingBottomForStyleableTextField").getStyle("gap");
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
			
			if ((value as MealEvent).insulinRatio != 0) {
				insulinAmount = ((Math.round((value as MealEvent).calculatedInsulinAmount * 10))/10).toString();
			}
			
			if ((value as MealEvent).selectedFoodItems != null) 
				if ((value as MealEvent).selectedFoodItems.length > 0) {
					selectedMealsDescriptionStrings = new ArrayCollection();
					selectedMealsCarbAmountStrings = new ArrayCollection();
					var selectedFoodItem:SelectedFoodItem = ((value as MealEvent).selectedFoodItems.getItemAt(0) as SelectedFoodItem);
					for (var i:int = 0 ; i < (value as MealEvent).selectedFoodItems.length ; i++) {
						selectedFoodItem = ((value as MealEvent).selectedFoodItems.getItemAt(i) as SelectedFoodItem);
						selectedMealsDescriptionStrings.addItem((Math.round(selectedFoodItem.chosenAmount * 10))/10 + " " + 
							selectedFoodItem.unit.unitDescription + " " + 
							selectedFoodItem.itemDescription);
						selectedMealsCarbAmountStrings.addItem(((Math.round(selectedFoodItem.chosenAmount * selectedFoodItem.unit.carbs / selectedFoodItem.unit.standardAmount * 10))/10).toString() );
					}
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

			
			if (!insulinDetails) {
				insulinDetails = new StyleableTextField();
				insulinDetails.styleName = this;
				insulinDetails.editable = false;
				insulinDetails.multiline = false;
				insulinDetails.wordWrap = false;
				insulinDetails.setStyle("fontSize",styleManager.getStyleDeclaration(".fontSizeForSubElements").getStyle("fontSize"));//other details is written a bit smaller, fontsize defined in style.css
				addChild(insulinDetails);
			}
			
		}
		
		// Override styleChanged() to proopgate style changes to compLabelDisplay.
		override public function styleChanged(styleName:String):void {
			super.styleChanged(styleName);
			
			// Pass any style changes to compLabelDisplay. 
			if (carbAmountDisplay)
				carbAmountDisplay.styleChanged(styleName);
			if (insulinDetails)
				insulinDetails.styleChanged(styleName);
			if (selectedMealsDescriptionStyleableTextFields)
				for (var l:int = 0;l < selectedMealsDescriptionStyleableTextFields.length; l++) {
					(selectedMealsDescriptionStyleableTextFields.getItemAt(l)).styleChanged(styleName);
					(selectedMealsCarbAmountStyleableTextFields.getItemAt(l)).styleChanged(styleName);
				}
		}
		
		// Override measure() to calculate the size required by the item renderer.
		override protected function measure():void {
//			super.measure();
				
			// Commit the styles changes to labelDisplay and carbAmount. 
			// This method must be called before the text is displayed, 
			// and any time the styles have changed. 
			// This method does nothing if the styles have already been committed. 
	//		labelDisplay.commitStyles();
		//	carbAmountDisplay.commitStyles();
			//if (insulinDetails)
				//insulinDetails.commitStyles();
			//if (selectedMealsDescriptionStyleableTextFields)
				//for (var l:int = 0;l < selectedMealsDescriptionStyleableTextFields.length; l++) {
					//(selectedMealsDescriptionStyleableTextFields.getItemAt(l)).commitStyles();
					//(selectedMealsCarbAmountStyleableTextFields.getItemAt(l)).commitStyles();
			//	}

			measuredHeight = getHeight();
			previousY = measuredHeight;
		}
		
		// Override layoutContents() to lay out the item renderer.
		override protected function layoutContents(unscaledWidth:Number, unscaledHeight:Number):void {
			// Because you are handling the layout of both the 
			// predefined labelDisplay component and the new 
			// carbAmount component, you do not have to call
			// super.layoutContents().
			
			// Commit the styles changes to labelDisplay and compLabelDisplay and others
			/*labelDisplay.commitStyles();
			carbAmountDisplay.commitStyles();
			if (insulinDetails)
				insulinDetails.commitStyles();
			if (selectedMealsDescriptionStyleableTextFields)
				for (var l:int = 0;l < selectedMealsDescriptionStyleableTextFields.length; l++) {
					(selectedMealsDescriptionStyleableTextFields.getItemAt(l)).commitStyles();
					(selectedMealsCarbAmountStyleableTextFields.getItemAt(l)).commitStyles();
				}*/
			
			if (MINIMUM_CARB_AMOUNT_WIDTH_LARGE_FONT == 100) {//most probably it's not yet been calculated
				carbAmountDisplay.commitStyles();
				// calculate MINIMUM_CARB_AMOUNT_WIDTH
				carbAmountDisplay.text = "9999 ...";
				MINIMUM_CARB_AMOUNT_WIDTH_LARGE_FONT = carbAmountDisplay.getLineMetrics(0).width;
			}
			
			
			//carbamount should have a minimum displaylength - labeldisplay will be shortened if needed
			//and then we'll extend carbamount if still possible
			//NEED TO CHECK ONCE WITH DEBUGGER IF THIS IS ALWAYS EQUAL TO MINIMUM_CARB_AMOUNT_WIDTH - I THINK SO BECAUSE HERE carbAmountDisplay has no text yet
			var carbAmountDisplayWidth:Number = Math.max(getElementPreferredWidth(carbAmountDisplay), MINIMUM_CARB_AMOUNT_WIDTH_LARGE_FONT);//that value is used later on also while creating field for selectedmealitems
			var labelDisplayWidth:Number = Math.min(getElementPreferredWidth(labelDisplay),unscaledWidth - PADDING_LEFT - PADDING_RIGHT - carbAmountDisplayWidth);
			carbAmountDisplay.text = carbAmount + " " + gramkh;
			carbAmountDisplayWidth = Math.min(unscaledWidth - PADDING_LEFT - labelDisplayWidth - GAP_HORIZONTAL_MINIMUM - PADDING_RIGHT, getElementPreferredWidth(carbAmountDisplay));
			
			if (_carbAmountCalculatedHeight == 0) {//which means also _carbAmountPreferredHeight == 0
				_carbAmountPreferredHeight = getElementPreferredHeight(carbAmountDisplay);
				setElementSize(labelDisplay,labelDisplayWidth,_carbAmountPreferredHeight);
				_carbAmountCalculatedHeight = labelDisplay.height;
			} else 
				setElementSize(labelDisplay,labelDisplayWidth,_carbAmountPreferredHeight);
			
			setElementSize(carbAmountDisplay,carbAmountDisplayWidth,_carbAmountPreferredHeight);
			labelDisplay.truncateToFit();
			carbAmountDisplay.truncateToFit();
			
			if (theMiddleOfCarbAmountField == 0)
				theMiddleOfCarbAmountField = (_carbAmountCalculatedHeight - _carbAmountPreferredHeight)/2
			setElementPosition(labelDisplay,0 + PADDING_LEFT,theMiddleOfCarbAmountField);
			setElementPosition(carbAmountDisplay,unscaledWidth - PADDING_RIGHT - carbAmountDisplayWidth,theMiddleOfCarbAmountField);
			var currentY:Number = _carbAmountCalculatedHeight - upLiftForNextField;
			
		    if (insulinAmount != null && insulinDetails != null) {
				insulinDetails.text = resourceManager.getString('general','calculated_insulin_amount') + " " + insulinAmount;
				if (_insulinAmountCalculatedHeight == 0) {
					_insulinAmountPreferredHeight = getElementPreferredHeight(insulinDetails);	
					setElementSize(insulinDetails,unscaledWidth - PADDING_RIGHT - PADDING_LEFT,_insulinAmountPreferredHeight);
					_insulinAmountCalculatedHeight = insulinDetails.height;
				} else
					setElementSize(insulinDetails,unscaledWidth - PADDING_RIGHT - PADDING_LEFT,_insulinAmountPreferredHeight);
				if (theMiddleOfInsulinField == 0)
					theMiddleOfInsulinField = (_carbAmountCalculatedHeight - _carbAmountPreferredHeight)/2
				setElementPosition(insulinDetails,0 + PADDING_LEFT,currentY + theMiddleOfInsulinField );
				currentY += _insulinAmountCalculatedHeight -upLiftForNextField;
			} else {
				setElementSize(insulinDetails,0,0);
			}
			
			if (selectedMealsDescriptionStrings != null) {
				if (selectedMealsCarbAmountStyleableTextFields == null || selectedMealsCarbAmountStyleableTextFields.length == 0)
					createSelectedMealCarbAmountStyleableTextFields(selectedMealsDescriptionStrings.length);
				if (selectedMealsDescriptionStyleableTextFields == null || selectedMealsCarbAmountStyleableTextFields.length == 0)
					createSelectedMealDescriptionStyleableTextFields(selectedMealsDescriptionStrings.length);
				for (var m:int; m < selectedMealsCarbAmountStyleableTextFields.length; m++) { 
					//resuing some variables already defined while calculating labelDisplay and carbAmountDisplay
					carbAmountDisplayWidth = Math.max(getElementPreferredWidth(selectedMealsCarbAmountStyleableTextFields.getItemAt(m) as StyleableTextField),MINIMUM_CARB_AMOUNT_WIDTH_SMALL_FONT);
					//carbAmountDisplayWidth = MINIMUM_CARB_AMOUNT_WIDTH_SMALL_FONT;
					(selectedMealsDescriptionStyleableTextFields.getItemAt(m) as StyleableTextField).text = selectedMealsDescriptionStrings.getItemAt(m) as String;
					labelDisplayWidth = Math.min(getElementPreferredWidth(selectedMealsDescriptionStyleableTextFields.getItemAt(m) as StyleableTextField),unscaledWidth - PADDING_LEFT - PADDING_RIGHT - carbAmountDisplayWidth);
					
					(selectedMealsCarbAmountStyleableTextFields.getItemAt(m) as StyleableTextField).text = (selectedMealsCarbAmountStrings.getItemAt(m) as String)  +  " " + gramkh;
					carbAmountDisplayWidth = Math.min(unscaledWidth - PADDING_LEFT - labelDisplayWidth - GAP_HORIZONTAL_MINIMUM - PADDING_RIGHT, getElementPreferredWidth(selectedMealsCarbAmountStyleableTextFields.getItemAt(m) as StyleableTextField));
					if (_selectedMealCalculatedHeight == 0) { //which means also _selectedMealPreferredHeight == 0
						_selectedMealPreferredHeight = getElementPreferredHeight((selectedMealsCarbAmountStyleableTextFields.getItemAt(m) as StyleableTextField));
						setElementSize(selectedMealsCarbAmountStyleableTextFields.getItemAt(m) as StyleableTextField,carbAmountDisplayWidth,_selectedMealPreferredHeight);
						_selectedMealCalculatedHeight = (selectedMealsCarbAmountStyleableTextFields.getItemAt(m) as StyleableTextField).height;
					} else 
						setElementSize(selectedMealsCarbAmountStyleableTextFields.getItemAt(m) as StyleableTextField,carbAmountDisplayWidth,_selectedMealPreferredHeight);
					
					setElementSize(selectedMealsDescriptionStyleableTextFields.getItemAt(m) as StyleableTextField,labelDisplayWidth,_selectedMealPreferredHeight);
					
					(selectedMealsDescriptionStyleableTextFields.getItemAt(m) as StyleableTextField).truncateToFit();
					(selectedMealsCarbAmountStyleableTextFields.getItemAt(m) as StyleableTextField).truncateToFit();
					
					if (theMiddleOfSelectedItemField == 0)
						theMiddleOfSelectedItemField = (_carbAmountCalculatedHeight - _carbAmountPreferredHeight)/2
					
					setElementPosition(selectedMealsDescriptionStyleableTextFields.getItemAt(m) as StyleableTextField,0 + PADDING_LEFT,currentY + theMiddleOfSelectedItemField);
					setElementPosition(selectedMealsCarbAmountStyleableTextFields.getItemAt(m) as StyleableTextField,unscaledWidth - PADDING_RIGHT - carbAmountDisplayWidth,currentY + theMiddleOfSelectedItemField);
					
					currentY += _selectedMealCalculatedHeight - upLiftForNextField;
				}
			} else {
				for (var p:int; p < selectedMealsCarbAmountStyleableTextFields.length; p++) { 
					//we should never come here because if there's no selectedMealsDescriptionStrings, then selectedMealCarbamountSTyleableTextFields will have no elements
					setElementSize(selectedMealsCarbAmountStyleableTextFields.getItemAt(p),0,0);
				}
			}
			
			//let's re-add some bottom offset
			currentY += upLiftForNextField;
			
			if (currentY != previousY) {
				previousY = currentY;
				invalidateSize();
			}
		}
		
		private function createSelectedMealDescriptionStyleableTextFields( amount:int):void {
			selectedMealsDescriptionStyleableTextFields = new ArrayCollection();
			for (var k:int = 0;k < amount; k++) {
				var tempStyleAbleTextField:StyleableTextField = new StyleableTextField();
				tempStyleAbleTextField.styleName = this;
				tempStyleAbleTextField.editable = false;
				tempStyleAbleTextField.multiline = false;
				tempStyleAbleTextField.wordWrap = false;
				tempStyleAbleTextField.setStyle("fontSize",styleManager.getStyleDeclaration(".fontSizeForSubElements").getStyle("fontSize"));//other details is written a bit smaller, fontsize defined in style.css
				addChild(tempStyleAbleTextField);
				selectedMealsDescriptionStyleableTextFields.addItem(tempStyleAbleTextField);
			}
		}
		
		private function createSelectedMealCarbAmountStyleableTextFields ( amount:int):void {
			selectedMealsCarbAmountStyleableTextFields = new ArrayCollection(); 
			for (var r:int = 0;r < selectedMealsCarbAmountStrings.length; r++) {
				var tempStyleAbleTextField2:StyleableTextField = new StyleableTextField();
				tempStyleAbleTextField2.styleName = this;
				tempStyleAbleTextField2.editable = false;
				tempStyleAbleTextField2.multiline = false;
				tempStyleAbleTextField2.wordWrap = false;
				tempStyleAbleTextField2.setStyle("fontSize",styleManager.getStyleDeclaration(".fontSizeForSubElements").getStyle("fontSize"));//other details is written a bit smaller, fontsize defined in style.css
				addChild(tempStyleAbleTextField2);
				selectedMealsCarbAmountStyleableTextFields.addItem(tempStyleAbleTextField2);
			}

			if (MINIMUM_CARB_AMOUNT_WIDTH_SMALL_FONT == 100) {//most probably it's not yet been calculated
				if (amount > 0) {
					// calculate MINIMUM_CARB_AMOUNT_WIDTH
					(selectedMealsCarbAmountStyleableTextFields.getItemAt(0) as StyleableTextField).text = "9999 ...";
					MINIMUM_CARB_AMOUNT_WIDTH_SMALL_FONT = getElementPreferredWidth(selectedMealsCarbAmountStyleableTextFields.getItemAt(0) as StyleableTextField);
				}
			}
			

		}
		
		override public function getHeight(item:TrackingViewElement = null):Number {  
			//if item = null then assign item to data, which may be (not sure yet) a mealevent
			//wheter it's a mealevent or not is checked by checking later against null value, if not null then it must be a mealevent
			if (item == null)
				item = (this.data as MealEvent);
			if (item == null) //parameter was null and this.data is also null, so there's nothing to calculate
				return 0;
			
			var returnValue:int = 0;
			//height of label and carbAmount
			returnValue += _carbAmountCalculatedHeight - upLiftForNextField;
			if ((item as MealEvent).insulinRatio != 0) {
				returnValue += _insulinAmountCalculatedHeight - upLiftForNextField;
			}
			//height of different selectedmeals
			if ((item as MealEvent).selectedFoodItems != null) {
				if ((item as MealEvent).selectedFoodItems.length > 0)
					returnValue += (_selectedMealCalculatedHeight - upLiftForNextField) * (item as MealEvent).selectedFoodItems.length;
			}
			//one uplift to be removed.
			returnValue += upLiftForNextField;
			
			return returnValue;
		}
		
		/**
		 * overriden because flex implementation seems to add a large separator above the item
		 */
		override protected function drawBackground(unscaledWidth:Number, unscaledHeight:Number):void
		{
			graphics.beginFill(0xFFFFFF,1);
			graphics.drawRect(0, 0, unscaledWidth, unscaledHeight);
			graphics.endFill();
		}
	}
}