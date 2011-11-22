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
	
	import flash.display.GradientType;
	import flash.geom.Matrix;
	
	import model.ModelLocator;

	public class ExerciseEventItemRenderer extends TrackingViewElementItemRenderer
	{
		/**
		 * padding left 
		 */
		private static const PADDING_LEFT:int = 5;
		/**
		 * padding right 
		 */
		private static const PADDING_RIGHT:int = 5;
		
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
				+ " " + (value as ExerciseEvent).level;
		}
		
		override public function getHeight(item:TrackingViewElement = null):Number {
			if (item == null)
				item = (this.data as ExerciseEvent);
			if (item == null) //parameter was null and this.data is also null, so there's nothing to calculate
				return 0;
			
			return ModelLocator.StyleableTextFieldCalculatedHeight;
		}
		
		override protected function layoutContents(unscaledWidth:Number, unscaledHeight:Number):void {
			setElementSize(labelDisplay,unscaledWidth - PADDING_LEFT - PADDING_RIGHT,ModelLocator.StyleableTextFieldPreferredHeight);
			labelDisplay.truncateToFit();
			
			setElementPosition(labelDisplay,0 + PADDING_LEFT,ModelLocator.offSetSoThatTextIsInTheMiddle);
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