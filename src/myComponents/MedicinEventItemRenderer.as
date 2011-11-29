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
	import databaseclasses.MedicinEvent;
	import databaseclasses.Settings;
	
	import flash.display.GradientType;
	import flash.geom.Matrix;
	import flash.text.TextLineMetrics;
	
	import model.ModelLocator;
	
	import spark.components.supportClasses.StyleableTextField;

	public class MedicinEventItemRenderer extends TrackingViewElementItemRenderer
	{
		private static var MINIMUM_AMOUNT_WIDTH:int = 100;
		
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
		
		private var amountDisplay:StyleableTextField;
		
		private var _amount:String;

		private function get amount():String
		{
			return _amount;
		}

		private function set amount(value:String):void
		{
			if (value == _amount)
				return;
			
			_amount = value;
			if (amountDisplay != null) {
				amountDisplay.text = _amount;
				invalidateSize();
			}
		}

		private static var _medicinEventBGColorDark:* = 0;
		private static var _medicinEventBGColorLight:* = 0;
		private static var backGroundColors:Array ;
		private static var alphas:Array = [1, 1];
		private static var ratios:Array = [0, 255];
		private static var matrix:Matrix = new Matrix();
		
		public function MedicinEventItemRenderer()
		{
			super();
			if (_medicinEventBGColorDark == 0) {
				_medicinEventBGColorDark = styleManager.getStyleDeclaration(".backGroundColorInLists").getStyle("medicinEventBackGroundDark");
				_medicinEventBGColorLight = styleManager.getStyleDeclaration(".backGroundColorInLists").getStyle("medicinEventBackGroundLight");
				backGroundColors = [_medicinEventBGColorDark, _medicinEventBGColorLight];
			}
		}

		override public function set data(value:Object):void {
			super.data = value;
			
			
			if (!data) return;//did this because I found it in an example 
			
			var date:Date = new Date(((value as MedicinEvent).timeStamp));
			label = 
				(date.hours.toString().length == 1 ? "0":"") + 	date.hours 
				+ ":"  
				+ (date.minutes.toString().length == 1 ? "0":"") + date.minutes 
				+ " " + (value as MedicinEvent).medicinName;
			
			amount = (value as MedicinEvent).amount.toString();
		}

		override protected function createChildren():void {
			super.createChildren();
			
			if (!amountDisplay) {
				amountDisplay = new StyleableTextField();
				amountDisplay.styleName = this;
				amountDisplay.editable = false;
				amountDisplay.multiline = false;
				amountDisplay.wordWrap = false;
				addChild(amountDisplay);
			}
			if (MINIMUM_AMOUNT_WIDTH == 0) {
				// calculate MINIMUM_CARB_AMOUNT_WIDTH
				var textLineMetricx:TextLineMetrics = this.measureText("999");
				MINIMUM_AMOUNT_WIDTH = textLineMetricx.width;
			}
		}

		override public function getHeight(item:TrackingViewElement = null):Number {
			if (item == null)
				item = (this.data as MedicinEvent);
			if (item == null) //parameter was null and this.data is also null, so there's nothing to calculate
				return 0;
			
			return ModelLocator.StyleableTextFieldCalculatedHeight;
		}
		
		override protected function layoutContents(unscaledWidth:Number, unscaledHeight:Number):void {
			var amountDisplayWidth:Number = Math.max(getElementPreferredWidth(amountDisplay), MINIMUM_AMOUNT_WIDTH);
			var labelDisplayWidth:Number = Math.min(getElementPreferredWidth(labelDisplay),unscaledWidth - PADDING_LEFT - PADDING_RIGHT - amountDisplayWidth);
			amountDisplay.text = amount + " " + resourceManager.getString('editmedicineventview','units');
			amountDisplayWidth = Math.min(unscaledWidth - PADDING_LEFT - labelDisplayWidth - GAP_HORIZONTAL_MINIMUM - PADDING_RIGHT, getElementPreferredWidth(amountDisplay));
			
			setElementSize(labelDisplay,labelDisplayWidth,ModelLocator.StyleableTextFieldPreferredHeight);
			setElementSize(amountDisplay,amountDisplayWidth,ModelLocator.StyleableTextFieldPreferredHeight);
			labelDisplay.truncateToFit();
			amountDisplay.truncateToFit();
			
			setElementPosition(labelDisplay,0 + PADDING_LEFT,ModelLocator.offSetSoThatTextIsInTheMiddle);
			setElementPosition(amountDisplay,unscaledWidth - PADDING_RIGHT - amountDisplayWidth,ModelLocator.offSetSoThatTextIsInTheMiddle);
		}
		
		override protected function drawBackground(unscaledWidth:Number, unscaledHeight:Number):void
		{
			matrix.createGradientBox(unscaledWidth, unscaledHeight, Math.PI / 2, 0, 0);
			graphics.beginGradientFill(GradientType.LINEAR, backGroundColors, alphas, ratios, matrix);
			graphics.drawRect(0, 0, unscaledWidth, unscaledHeight);
			graphics.endFill();
		}
	}
}