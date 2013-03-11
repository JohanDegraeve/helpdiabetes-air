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
	import databaseclasses.ExerciseEvent;
	import databaseclasses.Settings;
	
	import flash.display.GradientType;
	import flash.geom.Matrix;
	import flash.text.TextLineMetrics;
	
	import model.ModelLocator;
	
	import mx.graphics.BitmapFillMode;
	
	import spark.components.Image;
	import spark.components.supportClasses.StyleableTextField;
	
	public class ExerciseEventItemRenderer extends TrackingViewElementItemRenderer
	{
		private var eventTypeImage:Image;
		[Embed(source = "assets/ic_tab_exercise_selected_35x35.png")]
		public static var eventTypeIcon:Class;
		
		private var notesImage:Image;
		[Embed(source = "assets/Notes_16x16.png")]
		public static var notesIcon:Class;
		
		static private var itemHeight:int;
		static private var offsetToPutTextInTheMiddle:int;
		static private var iconHeight:int;
		static private var iconWidth:int;
		static private var notesIconWidthAndHeight:int = 17;
		
		private var exerciseLevelDisplay:StyleableTextField;
		
		private var _comment:String;

		public function get comment():String
		{
			return _comment;
		}

		public function set comment(value:String):void
		{
			if (_comment == value)
				return;
			_comment = value;
			if (comment == null)
				return;
			if (comment == "")
				return;
			if (!notesImage) {
				notesImage = new Image();
				notesImage.fillMode = BitmapFillMode.CLIP;
				notesImage.source = notesIcon;
				addChild(notesImage);
			}
		}

		
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
		
		public function ExerciseEventItemRenderer()
		{
			super();
			if (itemHeight ==  0) {
				itemHeight = styleManager.getStyleDeclaration(".trackingItems").getStyle("trackingeventHeight");
				offsetToPutTextInTheMiddle = styleManager.getStyleDeclaration(".trackingItems").getStyle("offsetToPutTextInTheMiddle");
				iconWidth = styleManager.getStyleDeclaration(".trackingItems").getStyle("iconWidth");
				iconHeight = styleManager.getStyleDeclaration(".trackingItems").getStyle("iconHeight");
			}
		}
		
		override public function set data(value:Object):void {
			super.data = value;
			
			if (!data) return;//did this because I found it in an example 
			
			var date:Date = new Date(((value as ExerciseEvent).timeStamp));
			label = 
				(date.hours.toString().length == 1 ? "0":"") + 	date.hours 
				+ ":"  
				+ (date.minutes.toString().length == 1 ? "0":"") + date.minutes; 
			//+ " " + resourceManager.getString('editexerciseeventview','exercise');
			
			exerciseLevel = (value as ExerciseEvent).level;
			comment = (value as ExerciseEvent).comment;
		}
		
		override protected function createChildren():void {
			super.createChildren();
			
			if (!eventTypeImage) {
				eventTypeImage = new Image();
				//image.smooth = true;
				//image.scaleMode = BitmapScaleMode.ZOOM;
				eventTypeImage.fillMode = BitmapFillMode.CLIP;
				eventTypeImage.source = eventTypeIcon;
				addChild(eventTypeImage);
			}
			
			if (!exerciseLevelDisplay) {
				exerciseLevelDisplay = new StyleableTextField();
				exerciseLevelDisplay.styleName = this;
				exerciseLevelDisplay.editable = false;
				exerciseLevelDisplay.multiline = false;
				exerciseLevelDisplay.wordWrap = false;
				addChild(exerciseLevelDisplay);
			}
			
			if (_comment != null)
				if (_comment != "") {
					if (!notesImage) {
						notesImage = new Image();
						notesImage.fillMode = BitmapFillMode.CLIP;
						notesImage.source = notesIcon;
						addChild(notesImage);
					}
				}
		}
		
		override public function getHeight(item:TrackingViewElement = null):Number {
			return itemHeight;
		}
		
		override protected function layoutContents(unscaledWidth:Number, unscaledHeight:Number):void {
			var labelDisplayWidth:Number = getElementPreferredWidth(labelDisplay);
			exerciseLevelDisplay.text = exerciseLevel ;
			var exerciseLevelDisplayWidth:Number  = Math.min(unscaledWidth - PADDING_LEFT - labelDisplayWidth - GAP_HORIZONTAL_MINIMUM - PADDING_RIGHT - iconWidth - (notesImage ? notesIconWidthAndHeight:0), getElementPreferredWidth(exerciseLevelDisplay));
			labelDisplayWidth = unscaledWidth;//setting back to maximum value, because it seems when there was a missing gap between labeldisplaywidt and glucosedisplaywidt, then click item doesn't work in trackingview
			
			setElementSize(labelDisplay,labelDisplayWidth,itemHeight);
			setElementSize(exerciseLevelDisplay,exerciseLevelDisplayWidth,itemHeight);
			setElementSize(eventTypeImage,iconWidth,iconHeight);
			exerciseLevelDisplay.truncateToFit();
			
			setElementPosition(labelDisplay,0  + iconWidth,offsetToPutTextInTheMiddle);
			setElementPosition(exerciseLevelDisplay,unscaledWidth - PADDING_RIGHT - exerciseLevelDisplayWidth - (notesImage ? notesIconWidthAndHeight:0),offsetToPutTextInTheMiddle);
			setElementPosition(eventTypeImage,0,0);
			
			if (notesImage)  {
				setElementSize(notesImage,notesIconWidthAndHeight,notesIconWidthAndHeight);
				setElementPosition(notesImage,unscaledWidth- notesIconWidthAndHeight,offsetToPutTextInTheMiddle);
			}
			
		}
		
		override protected function drawBackground(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.drawBackground(unscaledWidth,unscaledHeight);//to make the clicked items visible
		}
	}
}