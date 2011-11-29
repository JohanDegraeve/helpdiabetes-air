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
	import databaseclasses.ExerciseEvent;
	import databaseclasses.Settings;
	
	import flash.display.GradientType;
	import flash.geom.Matrix;
	import flash.text.TextLineMetrics;
	
	import model.ModelLocator;
	
	import spark.components.supportClasses.StyleableTextField;

	public class ExerciseEventItemRenderer extends TrackingViewElementItemRenderer
	{
		/**
		 * 
		 */
		private var exerciseLevelDisplay:StyleableTextField;
		
		private var _exerciseLevel:String;

		public function get exerciseLevel():String
		{
			return _exerciseLevel;
		}

		public function set exerciseLevel(value:String):void
		{
			if (_exerciseLevel == value)
				return;
			_exerciseLevel = value;
			if (exerciseLevelDisplay != null) {
				exerciseLevelDisplay.text = _exerciseLevel;
				invalidateSize();
			}
		}

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

		private static var _exerciseEventBGColorDark:* = 0;
		private static var _exerciseEventBGColorLight:* = 0;
		private static var backGroundColors:Array ;
		private static var alphas:Array = [1, 1];
		private static var ratios:Array = [0, 255];
		private static var matrix:Matrix = new Matrix();

		public function ExerciseEventItemRenderer()
		{
			super();
			if (_exerciseEventBGColorDark == 0) {
				_exerciseEventBGColorDark = styleManager.getStyleDeclaration(".backGroundColorInLists").getStyle("exerciseEventBackGroundDark");
				_exerciseEventBGColorLight = styleManager.getStyleDeclaration(".backGroundColorInLists").getStyle("exerciseEventBackGroundLight");
				backGroundColors = [_exerciseEventBGColorDark, _exerciseEventBGColorLight];
			}
		}
		
		override public function set data(value:Object):void {
			super.data = value;
			
			if (!data) return;//did this because I found it in an example 
			
			var date:Date = new Date(((value as ExerciseEvent).timeStamp));
			label = 
				(date.hours.toString().length == 1 ? "0":"") + 	date.hours 
				+ ":"  
				+ (date.minutes.toString().length == 1 ? "0":"") + date.minutes 
				+ " " + resourceManager.getString('editexerciseeventview','exercise');
			
			exerciseLevel = (value as ExerciseEvent).level;
		}
		
		override protected function createChildren():void {
			super.createChildren();
			
			if (!exerciseLevelDisplay) {
				exerciseLevelDisplay = new StyleableTextField();
				exerciseLevelDisplay.styleName = this;
				exerciseLevelDisplay.editable = false;
				exerciseLevelDisplay.multiline = false;
				exerciseLevelDisplay.wordWrap = false;
				addChild(exerciseLevelDisplay);
			}
			if (MINIMUM_AMOUNT_WIDTH == 0) {
				// calculate MINIMUM_CARB_AMOUNT_WIDTH
				var textLineMetricx:TextLineMetrics = this.measureText("piece of text");
				MINIMUM_AMOUNT_WIDTH = textLineMetricx.width;
			}
		}
		
		override public function getHeight(item:TrackingViewElement = null):Number {
			if (item == null)
				item = (this.data as ExerciseEvent);
			if (item == null) //parameter was null and this.data is also null, so there's nothing to calculate
				return 0;
			
			return ModelLocator.StyleableTextFieldCalculatedHeight;
		}
		
		override protected function layoutContents(unscaledWidth:Number, unscaledHeight:Number):void {
			
			var exerciseLevelDisplayWidth:Number = Math.max(getElementPreferredWidth(exerciseLevelDisplay), MINIMUM_AMOUNT_WIDTH);
			var labelDisplayWidth:Number = Math.min(getElementPreferredWidth(labelDisplay),unscaledWidth - PADDING_LEFT - PADDING_RIGHT - exerciseLevelDisplayWidth);
			exerciseLevelDisplay.text = exerciseLevel ;
			exerciseLevelDisplayWidth = Math.min(unscaledWidth - PADDING_LEFT - labelDisplayWidth - GAP_HORIZONTAL_MINIMUM - PADDING_RIGHT, getElementPreferredWidth(exerciseLevelDisplay));
			
			setElementSize(labelDisplay,labelDisplayWidth,ModelLocator.StyleableTextFieldPreferredHeight);
			setElementSize(exerciseLevelDisplay,exerciseLevelDisplayWidth,ModelLocator.StyleableTextFieldPreferredHeight);
			labelDisplay.truncateToFit();
			exerciseLevelDisplay.truncateToFit();
			
			setElementPosition(labelDisplay,0 + PADDING_LEFT,ModelLocator.offSetSoThatTextIsInTheMiddle);
			setElementPosition(exerciseLevelDisplay,unscaledWidth - PADDING_RIGHT - exerciseLevelDisplayWidth,ModelLocator.offSetSoThatTextIsInTheMiddle);
			
			/*
			setElementSize(labelDisplay,unscaledWidth - PADDING_LEFT - PADDING_RIGHT,ModelLocator.StyleableTextFieldPreferredHeight);
			labelDisplay.truncateToFit();
			
			setElementPosition(labelDisplay,0 + PADDING_LEFT,ModelLocator.offSetSoThatTextIsInTheMiddle);*/
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