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
		
		public function SelectedFoodItemRenderer()
		{
			super();
		}
		
		/**
		 * no background will be drawn
		 */
		override protected function drawBackground(unscaledWidth:Number, unscaledHeight:Number):void
		{
		}

		override public function set data(value:Object):void {
			_selectedFoodItem = value as SelectedFoodItem;
		}
		
		override protected function createChildren():void {
			super.createChildren();
			labelDisplay.multiline=true;
			labelDisplay.multiline=true;
			
			_amountOfCarbsEtc = new StyleableTextField();
			_amountOfCarbsEtc.styleName = this;
			_amountOfCarbsEtc.editable = false;
			_amountOfCarbsEtc.multiline = true;
			_amountOfCarbsEtc.wordWrap = true;
			_amountOfCarbsEtc.setStyle("fontSize",styleManager.getStyleDeclaration(".fontSizeForSubElements").getStyle("fontSize"));
			addChild(_amountOfCarbsEtc);
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
			var currentY:int=0;
			
			label = _selectedFoodItem.chosenAmount + " " + _selectedFoodItem.unit.unitDescription + " " + _selectedFoodItem.itemDescription;
			var fieldHeight:int = getElementPreferredHeight(labelDisplay);
			setElementSize(labelDisplay,unscaledWidth,fieldHeight);
			setElementPosition(labelDisplay,0,currentY);
			currentY = fieldHeight ; 
			
			_amountOfCarbsEtc.text = "balblabla";
			fieldHeight = getElementPreferredHeight(_amountOfCarbsEtc);
			setElementSize(_amountOfCarbsEtc,unscaledWidth,fieldHeight);
			setElementPosition(_amountOfCarbsEtc,0,currentY);
			currentY = currentY + fieldHeight;
			if (previousY < currentY) {
				previousY = currentY;
				invalidateSize();
			}
		}
	}	
}