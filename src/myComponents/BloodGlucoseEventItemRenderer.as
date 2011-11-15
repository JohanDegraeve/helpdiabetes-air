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
	import databaseclasses.BloodGlucoseEvent;
	import databaseclasses.Settings;
	
	import flash.display.GradientType;
	import flash.geom.Matrix;
	import flash.text.TextLineMetrics;
	
	import model.ModelLocator;
	
	import spark.components.supportClasses.StyleableTextField;

	public class BloodGlucoseEventItemRenderer extends TrackingViewElementItemRenderer
	{
		//*****************//
		// the display fields //
		// labelDisplay will be used to shown the first field with timestamp , amount in glucoseLevel will be on the right
		/**
		 * the field for the calculated amount of carbs - will be put on the right side of the first line, 
		 */
		private var glucoseLevelDisplay:StyleableTextField;
		
		private var _glucoseLevel:String;
		
		//private static var _bloodGlucoseCalculatedHeight:Number = 30;
		//private static var _bloodGlucosePreferredHeight:Number = 0;
		
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

		/**
		 * the bloodglucose level in a string
		 */
		private function get glucoseLevel():String
		{
			return _glucoseLevel;
		}

		/**
		 * @private
		 */
		private function set glucoseLevel(value:String):void
		{
			if (_glucoseLevel == value)
				return;
			_glucoseLevel = value;
			if (glucoseLevelDisplay != null) {
				glucoseLevelDisplay.text = _glucoseLevel;
				invalidateSize();
			}
		}
		
		private static var _bloodGlucseEventBGColorDark:* = 0;
		private static var _bloodGlucseEventBGColorLight:* = 0;
		private static var backGroundColors:Array ;
		private static var alphas:Array = [1, 1];
		private static var ratios:Array = [0, 255];
		private static var matrix:Matrix = new Matrix();
		
		public function BloodGlucoseEventItemRenderer()
		{
			super();
			if (_bloodGlucseEventBGColorDark == 0) {
				_bloodGlucseEventBGColorDark = styleManager.getStyleDeclaration(".backGroundColorInLists").getStyle("bloodGlucoseEventBackGroundDark");
				_bloodGlucseEventBGColorLight = styleManager.getStyleDeclaration(".backGroundColorInLists").getStyle("bloodGlucoseEventBackGroundLight");
				backGroundColors = [_bloodGlucseEventBGColorDark, _bloodGlucseEventBGColorLight];
			}

		}
		
		override public function set data(value:Object):void {
			super.data = value;
			
			//renderedBGEvent = (value as BloodGlucoseEvent);
			
			if (!data) return;//did this because I found it in an example 
			
			var date:Date = new Date(((value as BloodGlucoseEvent).timeStamp));
			label = 
				(date.hours.toString().length == 1 ? "0":"") + 	date.hours 
				+ ":"  
				+ (date.minutes.toString().length == 1 ? "0":"") + date.minutes 
				+ " " + resourceManager.getString('editbgeventview','glucose');
			
			glucoseLevel = (value as BloodGlucoseEvent).bloodGlucoseLevel.toString();
		}
		
		override protected function createChildren():void {
			super.createChildren();
			
			if (!glucoseLevelDisplay) {
				glucoseLevelDisplay = new StyleableTextField();
				glucoseLevelDisplay.styleName = this;
				glucoseLevelDisplay.editable = false;
				glucoseLevelDisplay.multiline = false;
				glucoseLevelDisplay.wordWrap = false;
				addChild(glucoseLevelDisplay);
			}
			if (MINIMUM_AMOUNT_WIDTH == 0) {
				// calculate MINIMUM_CARB_AMOUNT_WIDTH
				var textLineMetricx:TextLineMetrics = this.measureText("9999");
				MINIMUM_AMOUNT_WIDTH = textLineMetricx.width;
			}
		}
		
		override public function getHeight(item:TrackingViewElement = null):Number {
			if (item == null)
				item = (this.data as BloodGlucoseEvent);
			if (item == null) //parameter was null and this.data is also null, so there's nothing to calculate
				return 0;
			
			return ModelLocator.StyleableTextFieldCalculatedHeight;
		}
		
		override protected function layoutContents(unscaledWidth:Number, unscaledHeight:Number):void {
			var glucoseLevelDisplayWidth:Number = Math.max(getElementPreferredWidth(glucoseLevelDisplay), MINIMUM_AMOUNT_WIDTH);
			var labelDisplayWidth:Number = Math.min(getElementPreferredWidth(labelDisplay),unscaledWidth - PADDING_LEFT - PADDING_RIGHT - glucoseLevelDisplayWidth);
			glucoseLevelDisplay.text = glucoseLevel + " " + resourceManager.getString('general',Settings.getInstance().getSetting(Settings.SettingsBLOODGLUCOSE_UNIT));
			glucoseLevelDisplayWidth = Math.min(unscaledWidth - PADDING_LEFT - labelDisplayWidth - GAP_HORIZONTAL_MINIMUM - PADDING_RIGHT, getElementPreferredWidth(glucoseLevelDisplay));

			setElementSize(labelDisplay,labelDisplayWidth,ModelLocator.StyleableTextFieldPreferredHeight);
			setElementSize(glucoseLevelDisplay,glucoseLevelDisplayWidth,ModelLocator.StyleableTextFieldPreferredHeight);
			labelDisplay.truncateToFit();
			glucoseLevelDisplay.truncateToFit();
			
			setElementPosition(labelDisplay,0 + PADDING_LEFT,ModelLocator.offSetSoThatTextIsInTheMiddle);
			setElementPosition(glucoseLevelDisplay,unscaledWidth - PADDING_RIGHT - glucoseLevelDisplayWidth,ModelLocator.offSetSoThatTextIsInTheMiddle);
		}
		
		/**
		 * overriden because flex implementation seems to add a large separator above the item
		 */
		override protected function drawBackground(unscaledWidth:Number, unscaledHeight:Number):void
		{
			matrix.createGradientBox(unscaledWidth, unscaledHeight, Math.PI / 2, 0, 0);
			graphics.beginGradientFill(GradientType.LINEAR, backGroundColors, alphas, ratios, matrix);
			graphics.drawRect(0, 0, unscaledWidth, unscaledHeight);
			graphics.endFill();
		}
		

	}
}