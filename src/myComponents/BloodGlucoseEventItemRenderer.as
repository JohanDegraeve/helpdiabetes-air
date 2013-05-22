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
	import databaseclasses.BloodGlucoseEvent;
	import flash.text.TextLineMetrics;
	
	import mx.graphics.BitmapFillMode;
	
	import spark.components.Image;
	import spark.components.supportClasses.StyleableTextField;

	public class BloodGlucoseEventItemRenderer extends TrackingViewElementItemRenderer
	{
		private var eventTypeImage:Image;
		[Embed(source="assets/ic_tab_glucose_selected_35x35.png")]
		[Bindable]
		public var eventTypeIcon:Class;

		private var notesImage:Image;
		[Embed(source = "assets/Notes_16x16.png")]
		public static var notesIcon:Class;

		static private var itemHeight:int;
		static private var offsetToPutTextInTheMiddle:int;
		static private var iconHeight:int;
		static private var iconWidth:int;
		static private var notesIconWidthAndHeight:int = 17;
		
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

		//*****************//
		// the display fields //
		// labelDisplay will be used to shown the first field with timestamp , amount in glucoseLevel will be on the right
		/**
		 * the field for the calculated amount of carbs - will be put on the right side of the first line, 
		 */
		private var glucoseLevelDisplay:StyleableTextField;
		
		private var _glucoseLevel:String;
		
		private var _unit:String;

		public function get unit():String

		{
			return _unit;
		}

		public function set unit(value:String):void

		{
			if (_unit == value)
				return;
			_unit = value;
			if (glucoseLevelDisplay != null) {
				glucoseLevelDisplay.text = _glucoseLevel;
				invalidateSize();
			}
		}

		
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
				glucoseLevelDisplay.text = glucoseLevel + " " + unit;
				invalidateSize();
			}
		}
		
		
		
		public function BloodGlucoseEventItemRenderer()
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
			
			//renderedBGEvent = (value as BloodGlucoseEvent);
			
			if (!data) return;//did this because I found it in an example 
			
			var date:Date = new Date(((value as BloodGlucoseEvent).timeStamp));
			label = 
				(date.hours.toString().length == 1 ? "0":"") + 	date.hours 
				+ ":"  
				+ (date.minutes.toString().length == 1 ? "0":"") + date.minutes 
				;
			
			glucoseLevel = (value as BloodGlucoseEvent).bloodGlucoseLevel.toString();
			unit = (value as BloodGlucoseEvent).unit;
			comment = (value as BloodGlucoseEvent).comment;
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
			var glucoseLevelDisplayWidth:Number = Math.max(getElementPreferredWidth(glucoseLevelDisplay), MINIMUM_AMOUNT_WIDTH);
			var labelDisplayWidth:Number = Math.min(getElementPreferredWidth(labelDisplay),unscaledWidth - PADDING_LEFT - PADDING_RIGHT - glucoseLevelDisplayWidth - iconWidth- (notesImage ? notesIconWidthAndHeight:0));
			glucoseLevelDisplay.text = glucoseLevel + " " + unit ;
			glucoseLevelDisplayWidth = Math.min(unscaledWidth - PADDING_LEFT - labelDisplayWidth - GAP_HORIZONTAL_MINIMUM - PADDING_RIGHT, getElementPreferredWidth(glucoseLevelDisplay));
			labelDisplayWidth = unscaledWidth;//setting back to maximum value, because it seems when there was a missing gap between labeldisplaywidt and glucosedisplaywidt, then click item doesn't work in trackingview
			
			setElementSize(labelDisplay,labelDisplayWidth,itemHeight);
			setElementSize(glucoseLevelDisplay,glucoseLevelDisplayWidth,itemHeight);
			setElementSize(eventTypeImage,iconWidth,iconHeight);
			glucoseLevelDisplay.truncateToFit();
			
			setElementPosition(labelDisplay,0  + iconWidth,offsetToPutTextInTheMiddle);
			setElementPosition(glucoseLevelDisplay,unscaledWidth - PADDING_RIGHT - glucoseLevelDisplayWidth- (notesImage ? notesIconWidthAndHeight:0),offsetToPutTextInTheMiddle);
			setElementPosition(eventTypeImage,0,0);
			if (notesImage)  {
				setElementSize(notesImage,notesIconWidthAndHeight,notesIconWidthAndHeight);
				setElementPosition(notesImage,unscaledWidth- notesIconWidthAndHeight,offsetToPutTextInTheMiddle);
			}
		}
		
		/**
		 * overriden because flex implementation seems to add a large separator above the item
		 */
		override protected function drawBackground(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.drawBackground(unscaledWidth,unscaledHeight);//to make the clicked items visible
		}
		

	}
}