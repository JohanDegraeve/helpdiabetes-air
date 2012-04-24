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
/**
 * to be used in editmealview, only reason why I define it is to put background to none<br>
 * 
 */

package myComponents
{
	import databaseclasses.SelectedFoodItem;
	
	import flash.display.GradientType;
	import flash.geom.Matrix;
	
	import flashx.textLayout.factory.TruncationOptions;
	import flashx.textLayout.formats.BackgroundColor;
	
	import spark.components.DataGroup;
	import spark.components.LabelItemRenderer;
	import spark.components.supportClasses.StyleableTextField;
	
	/**
	 * to show a selected meal in editmealview<br>
	 * the label is used to display the fooditem description + unit + chosen amount<br>
	 * then below that, a styleabletextfield is added to show amount of carbs, fat, protein, ...
	 */
	public class SelectedFoodItemRenderer extends LabelItemRenderer
	{
		//all variables to maintain previous heights, if changed then invalidatesize must be called.
		private var previousY:Number = 0;

		private var _amountOfCarbsEtc:StyleableTextField;
		
		private var _selectedFoodItem:SelectedFoodItem;
		
		/**
		 * the text for the amountOfCarbsEtcText styleable textfield
		 */
		private var _amountOfCarbsEtcText:String;

		/**
		 * the text for the amountOfCarbsEtcText styleable textfield
		 */
		private function get amountOfCarbsEtcText():String

		{
			return _amountOfCarbsEtcText;
		}

		/**
		 * the text for the amountOfCarbsEtcText styleable textfield
		 */
		private function set amountOfCarbsEtcText(value:String):void
		{
			if (value == _amountOfCarbsEtcText)
				return;
			_amountOfCarbsEtcText = value;
			if (_amountOfCarbsEtc != null) {
				_amountOfCarbsEtc.text = _amountOfCarbsEtcText;
				invalidateSize();
			}
		}
		
		/**
		 * the text for the amountOfCarbsEtcText styleable textfield
		 */
		private var _labelDisplayText:String;
		
		/**
		 * the text for the amountOfCarbsEtcText styleable textfield
		 */
		private function get labelDisplayText():String
		{
			return _labelDisplayText;
		}
		/**
		 * the text for the amountOfCarbsEtcText styleable textfield
		 */
		private function set labelDisplayText(value:String):void
		{
			if (value == _labelDisplayText)
				return;
			_labelDisplayText = value;
			if (labelDisplay != null) {
				label = value;
				invalidateSize();
			}
		}
		
		private static var  paddingLeft:Number = -1 ; 
		private  static var  paddingRight:Number;
		private  static var  paddingTop:Number  ;
		private  static var  paddingBottom:Number;
		
		public function SelectedFoodItemRenderer()
		{
			super();
			if (paddingLeft == -1) {
				 paddingLeft   = styleManager.getStyleDeclaration(".fontSizeForSubElements").getStyle("paddingLeft"); 
				 paddingRight  = styleManager.getStyleDeclaration(".fontSizeForSubElements").getStyle("paddingRight");
				 paddingTop    = styleManager.getStyleDeclaration(".fontSizeForSubElements").getStyle("paddingTop");
				 paddingBottom = styleManager.getStyleDeclaration(".fontSizeForSubElements").getStyle("paddingBottom");
			}
		}
		
		/**
		 * each subsequent item will be drawn in another backgroundcolor, either mealEventBGColorDark or mealEventBGColorLight
		 */
		override protected function drawBackground(unscaledWidth:Number, unscaledHeight:Number):void
		{
			if (down) {
				graphics.beginFill(0, 0.25);
				graphics.drawRect(0, 0, unscaledWidth, unscaledHeight);
				graphics.endFill();
			}
		}
		

		override public function set data(value:Object):void {
			_selectedFoodItem = value as SelectedFoodItem;
			labelDisplayText =  _selectedFoodItem.chosenAmount + " " + _selectedFoodItem.unit.unitDescription + " " + _selectedFoodItem.itemDescription;
			amountOfCarbsEtcText = (Math.round((_selectedFoodItem.chosenAmount * _selectedFoodItem.unit.carbs / _selectedFoodItem.unit.standardAmount)*10))/10 + " " + resourceManager.getString('general','gram_of_carbs');
		}
		
		override protected function createChildren():void {
			super.createChildren();

			if (!_amountOfCarbsEtc) {
				_amountOfCarbsEtc = new StyleableTextField();
				_amountOfCarbsEtc.styleName = this;
				_amountOfCarbsEtc.editable = false;
				_amountOfCarbsEtc.multiline = true;
				_amountOfCarbsEtc.wordWrap = true;
				_amountOfCarbsEtc.setStyle("fontSize",styleManager.getStyleDeclaration(".fontSizeForSubElements").getStyle("fontSize"));
				addChild(_amountOfCarbsEtc);
			}
		}
		
		override protected function createLabelDisplay():void {
			super.createLabelDisplay();
			labelDisplay.styleName = this;
			labelDisplay.editable = false;
			labelDisplay.multiline = true;
			labelDisplay.wordWrap = true;
		}
		
		// Override styleChanged() to proopgate style changes to compLabelDisplay.
		override public function styleChanged(styleName:String):void {
			super.styleChanged(styleName);
			
			if (_amountOfCarbsEtc)
				_amountOfCarbsEtc.styleChanged(styleName);
		}

		
		override protected function measure():void {
			//layout of an item is similar to a mealevent in trackingview with some exception
			//the label will be seized as the the label in a mealevent, namely that has the timestamp, mealname and amount of carbs
			//the next added field is _amountOfCarbsEtc which may have multiple lines, however, assuming it's only one line, it would have the same size as insulinAmount
			//this values are static in MealEventItemRenderer
			if (previousY == 0) {
				measuredHeight = MealEventItemRenderer.carbAmountCalculatedHeight - MealEventItemRenderer.upLiftForNextField /*+ MealEventItemRenderer.insulinAmountCalculatedHeight*/;
				previousY = measuredHeight;
			} else
				measuredHeight = previousY;
		}
		
		override protected function layoutContents(unscaledWidth:Number, unscaledHeight:Number):void {
			super.layoutContents(unscaledWidth,unscaledHeight);
			var currentY:int=0;
			setElementPosition(labelDisplay,labelDisplay.x,paddingTop);

			setElementSize(_amountOfCarbsEtc,unscaledWidth ,getElementPreferredHeight(_amountOfCarbsEtc));
			//_amountOfCarbsEtc.truncateToFit();
			setElementPosition(_amountOfCarbsEtc,paddingLeft, labelDisplay.height/*currentY /*+ mid*/);
			currentY = paddingTop + labelDisplay.height + _amountOfCarbsEtc.height;
			if (previousY != currentY) {
				previousY = currentY;
				invalidateSize();
			}
		}
	}	
}