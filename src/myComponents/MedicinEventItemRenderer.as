/**
 Copyright (C) 2016  hippoandfriends
 
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
	import mx.graphics.BitmapFillMode;
	
	import spark.components.Image;
	import spark.components.supportClasses.StyleableTextField;
	
	import databaseclasses.MedicinEvent;
	
	import model.ModelLocator;

	public class MedicinEventItemRenderer extends TrackingViewElementItemRenderer
	{
		private var eventTypeImage:Image;
		//[Embed(source = "assets/ic_tab_medicine_selected_35x35.png")]
		//public static var eventTypeIcon:Class;
		
		private var notesImage:Image;
		//[Embed(source = "assets/Notes_16x16.png")]
		//public static var notesIcon:Class;

		private var squareWaveBolusImage:Image;
		//[Embed(source = "assets/squarewavebolus.png")]
		//public static var squareWaveBolusIcon:Class;

		static private var itemHeight:int;
		static private var offsetToPutTextInTheMiddle:int;
		static private var iconHeight:int;
		static private var iconWidth:int;
		static private var notesIconWidthAndHeight:int = 17;
		static private var squareWaveBolusWidthAndHeight:int = 17;
		static private var activeInsulinAmountHeight:int;
	
		/**
		 * the field for the calculated insulinAmount 
		 */
		private var activeInsulinAmountDisplay:StyleableTextField;
		
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
		
		private var _comment:String;
		
		public function get comment():String
		{
			return _comment;
		}
		/**
		 * if styleabletextfield is added, then paddingbottom is too high, next element will be uplifted by an amount of pixels which is upLiftForNextField.
		 */
		private static var _upLiftForNextField:int;
		public static function get upLiftForNextField():int
			
		{
			return _upLiftForNextField;
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
				notesImage.contentLoader = ModelLocator.iconCache;
				notesImage.source = "assets/Notes_16x16.png";
				addChild(notesImage);
			}
		}
		
		private var _activeInsulinAmount:String
		
		public function get activeInsulinAmount():String
		{
			return _activeInsulinAmount;
		}

		public function set activeInsulinAmount(value:String):void
		{
			if (_activeInsulinAmount == value)
				return;
			_activeInsulinAmount = value;
			if (activeInsulinAmount == null)
				return;
			if (activeInsulinAmount == "")
				return;
			if (activeInsulinAmountDisplay == null) {
				activeInsulinAmountDisplay = new StyleableTextField();
				activeInsulinAmountDisplay.styleName = this;
				activeInsulinAmountDisplay.editable = false;
				activeInsulinAmountDisplay.multiline = false;
				activeInsulinAmountDisplay.wordWrap = false;
				activeInsulinAmountDisplay.setStyle("fontSize",styleManager.getStyleDeclaration(".fontSizeForSubElements").getStyle("fontSize"));//other details is written a bit smaller, fontsize defined in style.css
				addChild(activeInsulinAmountDisplay);
			}
			activeInsulinAmountDisplay.text = _activeInsulinAmount;
			invalidateSize();
		}

		private var _bolusType:String

		public function get bolusType():String
		{
			return _bolusType;
		}

		public function set bolusType(value:String):void
		{
			if (_bolusType == value)
				return;
			_bolusType = value;
			if (bolusType == null)
				return;
			if (bolusType == "")
				return;
			if (resourceManager.getString('editmedicineventview','listofsquarewavebolustypes').indexOf(bolusType) > -1) {
				if (!squareWaveBolusImage) {
					squareWaveBolusImage  = new Image();
					squareWaveBolusImage.fillMode = BitmapFillMode.CLIP;
					squareWaveBolusImage.source = "assets/squarewavebolus.png";
					addChild(squareWaveBolusImage)
				}
			} else
				squareWaveBolusImage = null;
		}

		
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

		public function MedicinEventItemRenderer()
		{
			super();
			if (itemHeight ==  0) {
				itemHeight = styleManager.getStyleDeclaration(".trackingItems").getStyle("trackingeventHeight");
				offsetToPutTextInTheMiddle = styleManager.getStyleDeclaration(".trackingItems").getStyle("offsetToPutTextInTheMiddle");
				iconWidth = styleManager.getStyleDeclaration(".trackingItems").getStyle("iconWidth");
				iconHeight = styleManager.getStyleDeclaration(".trackingItems").getStyle("iconHeight");
				activeInsulinAmountHeight = styleManager.getStyleDeclaration(".trackingItems").getStyle("selectedMealHeight");
				_upLiftForNextField = styleManager.getStyleDeclaration(".removePaddingBottomForStyleableTextField").getStyle("gap");

			}
		}
		
		private static var counter2:int = 0;

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
			comment = (value as MedicinEvent).comment;
			bolusType = (value as MedicinEvent).bolustype;
			var now:Number = (new Date()).valueOf();
			trace("in MedicineventItemrender.set data, callling nr " + counter2++);
			var activeInsulin:Number = ModelLocator.calculateActiveInsulinForSpecifiedEvent((value as MedicinEvent),now);
			if (activeInsulin > 0) {
				var activeInsulinText:String = resourceManager.getString('editmedicineventview','active') 
					+ " = " + ((Math.round(activeInsulin * 10))/10).toString()
					+ " " + resourceManager.getString('trackingview','internationalunit');
				if (resourceManager.getString('editmedicineventview','listofsquarewavebolustypes').indexOf(bolusType) > -1) {
					var timeToGo:Number = now - ((value as MedicinEvent).timeStamp) - (value as MedicinEvent).bolusDurationInMinutes * 60 * 1000; 
					if (timeToGo <= 0) {
						activeInsulinText += ", " + (- Math.round((timeToGo / 1000 / 60 / 60 * 10)) / 10).toString() +  " " + resourceManager.getString('editmedicineventview','hrtogo');
					} else {
						if (activeInsulin == 0) //should not happen anymore because I already checked if activeInsulin > 0, piece of code that has been changed
							activeInsulinText = "";
					} 
				} else {
					if (activeInsulin == 0) //should not happen anymore because I already checked if activeInsulin > 0, piece of code that has been changed
						activeInsulinText = "";
				}
			}
				
			activeInsulinAmount = activeInsulinText;
		}

		override protected function createChildren():void {
			super.createChildren();
			
			if (!eventTypeImage) {
				eventTypeImage = new Image();
				//image.smooth = true;
				//image.scaleMode = BitmapScaleMode.ZOOM;
				eventTypeImage.fillMode = BitmapFillMode.CLIP;
				eventTypeImage.contentLoader = ModelLocator.iconCache;
				eventTypeImage.source = "assets/ic_tab_medicine_selected_35x35.png";
				addChild(eventTypeImage);
			}
			
			if (!amountDisplay) {
				amountDisplay = new StyleableTextField();
				amountDisplay.styleName = this;
				amountDisplay.editable = false;
				amountDisplay.multiline = false;
				amountDisplay.wordWrap = false;
				addChild(amountDisplay);
			}
			if (_comment != null)
				if (_comment != "") {
					if (!notesImage) {
						notesImage = new Image();
						notesImage.fillMode = BitmapFillMode.CLIP;
						notesImage.contentLoader = ModelLocator.iconCache;
						notesImage.source = "assets/Notes_16x16.png";
						addChild(notesImage);
					}
				}
			
			if (bolusType == resourceManager.getString('editmedicineventview','square')) {
				if (!squareWaveBolusImage) {
					squareWaveBolusImage  = new Image();
					squareWaveBolusImage.fillMode = BitmapFillMode.CLIP;
					squareWaveBolusImage.source = "assets/squarewavebolus.png";
					addChild(squareWaveBolusImage)
				}
			} 
		}

		private static var counter1:int = 0;
		override public function getHeight(item:TrackingViewElement = null):Number {
			var now:Number = (new Date()).valueOf();
			trace("in MedicineventItemrender.getHeight, callling nr " + counter1++);
			var activeInsulin:Number = ModelLocator.calculateActiveInsulinForSpecifiedEvent((item as MedicinEvent),now);
			return itemHeight + (activeInsulin == 0  ? 0 : activeInsulinAmountHeight);
		}

		override protected function layoutContents(unscaledWidth:Number, unscaledHeight:Number):void {
			amountDisplay.text = amount + " " + resourceManager.getString('trackingview','internationalunit');
			var amountDisplayWidth:Number = getElementPreferredWidth(amountDisplay);
			var labelDisplayWidth:Number = Math.min(getElementPreferredWidth(labelDisplay),unscaledWidth - PADDING_LEFT - PADDING_RIGHT - amountDisplayWidth - iconWidth - (notesImage ? notesIconWidthAndHeight:0) - (squareWaveBolusImage ? squareWaveBolusWidthAndHeight:0) );
			amountDisplayWidth = Math.min(unscaledWidth - PADDING_LEFT - labelDisplayWidth - GAP_HORIZONTAL_MINIMUM - PADDING_RIGHT, getElementPreferredWidth(amountDisplay));
			if (iconWidth + (notesImage ? notesIconWidthAndHeight:0) + (squareWaveBolusImage ? squareWaveBolusWidthAndHeight:0) + labelDisplayWidth + amountDisplayWidth + PADDING_RIGHT + GAP_HORIZONTAL_MINIMUM < unscaledWidth)
				labelDisplayWidth = unscaledWidth;//same reason as in exerciseventitemrenderer and bgeventitemrender but this works better
			
			setElementSize(labelDisplay,labelDisplayWidth,itemHeight);
			setElementSize(amountDisplay,amountDisplayWidth,itemHeight);
			setElementSize(eventTypeImage,iconWidth,iconHeight);
			labelDisplay.truncateToFit();
			amountDisplay.truncateToFit();
			
			setElementPosition(eventTypeImage,0,0);
			setElementPosition(labelDisplay,0  + iconWidth,offsetToPutTextInTheMiddle);
			setElementPosition(amountDisplay,unscaledWidth - PADDING_RIGHT - amountDisplayWidth - (notesImage ? notesIconWidthAndHeight:0) - (squareWaveBolusImage ? squareWaveBolusWidthAndHeight:0),offsetToPutTextInTheMiddle);
			if (notesImage)  {
				setElementSize(notesImage,notesIconWidthAndHeight,notesIconWidthAndHeight);
				setElementPosition(notesImage,unscaledWidth- notesIconWidthAndHeight - (squareWaveBolusImage ? squareWaveBolusWidthAndHeight:0),offsetToPutTextInTheMiddle);
			}
			if (squareWaveBolusImage) {
				setElementSize(squareWaveBolusImage,squareWaveBolusWidthAndHeight,squareWaveBolusWidthAndHeight);
				setElementPosition(squareWaveBolusImage,unscaledWidth- squareWaveBolusWidthAndHeight ,offsetToPutTextInTheMiddle);
			}
			if (activeInsulinAmountDisplay != null) {
				setElementSize(activeInsulinAmountDisplay,unscaledWidth - PADDING_RIGHT - PADDING_LEFT,activeInsulinAmountHeight);
				setElementPosition(activeInsulinAmountDisplay,0 + PADDING_LEFT,itemHeight + offsetToPutTextInTheMiddle - _upLiftForNextField);
			}
		}
		
		override protected function drawBackground(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.drawBackground(unscaledWidth,unscaledHeight);//to make the clicked items visible
		}
	}
}