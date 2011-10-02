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
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.StyleSheet;
	
	import model.ModelLocator;
	
	import mx.events.FlexEvent;
	import mx.events.ValidationResultEvent;
	import mx.validators.NumberValidator;
	import mx.validators.ValidationResult;
	
	import spark.components.Button;
	import spark.components.DataGroup;
	import spark.components.Group;
	import spark.components.supportClasses.GroupBase;
	import spark.components.supportClasses.StyleableTextField;
	import spark.globalization.StringTools;
	import spark.skins.mobile.supportClasses.MobileSkin;
	
	public class AddFoodItemGroup extends Group
	{
		//*********************
		// textfield with description area
		//*********************
		private var _description_textarea_text:String;

		public function get description_textarea_text():String
		{
			return _description_textarea_text;
		}

		public function set description_textarea_text(value:String):void
		{
			if (_description_textarea_text == value)
				return;
			_description_textarea_text = value;
			if (description_textarea) {
				description_textarea.text = value;
				invalidateDisplayList();
			}
		}
		
		private var description_textarea:StyleableTextField;

		//*********************
		// button with details like chosen amount, amount of carbs ..., when clicked, user can change the unit
		//*********************
		private var _details_button_text:String ;
		
		[Bindable]
		public function get details_button_text():String
		{
			return _details_button_text;
		}

		public function set details_button_text(value:String):void
		{
			if (_details_button_text == value)
				return;
			_details_button_text = value;
			if (details_button) {
				details_button.label = value;
				invalidateDisplayList();
			}
		}
		
		private var details_button:Button;
		
		private var _details_button_click_function:Function;

		/**
		 * the function that will be called when the button is clicked 
		 */
		public function get details_button_click_function():Function
		{
			return _details_button_click_function;
		}

		/**
		 * @private
		 */
		public function set details_button_click_function(value:Function):void
		{
			_details_button_click_function = value;
			if (details_button) {
				details_button.addEventListener(MouseEvent.CLICK,_details_button_click_function);
			}
		}


		//*********************
		// amount entered by the user, can be editable in case buttons are not used
		//*********************
		private var _amount_textinput_text:String;

		[Bindable]
		public function get amount_textinput_text():String
		{
			return _amount_textinput_text;
		}

		public function set amount_textinput_text(value:String):void
		{
			if (_amount_textinput_text == value)
				return;
			_amount_textinput_text = value;
			if (amount_textinput) {
				amount_textinput.htmlText = "<p>"+value+"</p>";
				callLater(function():void{
					var myStyleSheet:StyleSheet = new StyleSheet();
					myStyleSheet.parseCSS(defaultAmountOverwritten ? "p {color:#000000;}":"p {color:#9F9E9E;}");
					amount_textinput.styleSheet = myStyleSheet;
				}); 
				invalidateDisplayList();
			}
		}
		
		private var amount_textinput:StyleableTextField;
		
		
		private var _amountTextChangedFunction:Function;

		public function get amountTextChangedFunction():Function
		{
			return _amountTextChangedFunction;
		}

		public function set amountTextChangedFunction(value:Function):void
		{
			if (_amountTextChangedFunction == value)
				return;
			_amountTextChangedFunction = value;
		}

		
		//*********************
		// the static text saying meal...
		//*********************
		private var _meal_textarea_text:String;

		[Bindable]
		public function get meal_textarea_text():String
		{
			return _meal_textarea_text;
		}

		public function set meal_textarea_text(value:String):void
		{
			if (_meal_button_text == value)
				return;
			_meal_textarea_text = value;
			if (meal_textarea) {
				meal_textarea.text = value;
				invalidateDisplayList();
			}
		}
		
		private var meal_textarea:StyleableTextField;

		//*********************
		// the static text saying amount
		//*********************
		private var _amount_textarea_text:String;

		public function get amount_textarea_text():String
		{
			return _amount_textarea_text;
		}

		public function set amount_textarea_text(value:String):void
		{
			if (_amount_textarea_text == value)
				return;
			_amount_textarea_text = value;
			if (amount_textarea) {
				amount_textarea.text = value;
				invalidateDisplayList();
			}
		}
		
		private var amount_textarea:StyleableTextField;

		//*********************
		// the button to change the meal
		//*********************
		private var _meal_button_text:String;

		public function get meal_button_text():String
		{
			return _meal_button_text;
		}

		public function set meal_button_text(value:String):void
		{
			if (_meal_button_text == value)
				return;
			_meal_button_text = value;
			if (meal_button) {
				meal_button.label = value;
				invalidateDisplayList();
			}
		}
		
		private var meal_button:Button;
		
		/**
		 * the function to call when meal button is clicked 
		 */
		private var _meal_button_click_function:Function;
		
		/**
		 * the function that will be called when the button is clicked 
		 */
		public function get meal_button_click_function():Function
		{
			return _meal_button_click_function;
		}
		
		/**
		 * @private
		 */
		public function set meal_button_click_function(value:Function):void
		{
			_meal_button_click_function = value;
			if (meal_button) {
				meal_button.addEventListener(MouseEvent.CLICK,_meal_button_click_function);
			}
		}
		
		
		
		/**
		 * are the buttonsizes already known or not. 
		 */
		static private var buttonSizesKnown:Boolean = false;
		/**
		 * the minimum width of a digit button
		 */
		static private var buttonMinimumWidth:int;
		/**
		 * the maximum width of a digit button
		 */
		static private var buttonMaximumWidth:int;
		/**
		 *  the minimum height of such a button 
		 */
		static private var buttonMinimumHeight:int;
		/**
		 * the maximum height of such a button
		 */
		static private var buttonMaximumHeight:int;
		/**
		 * gap between buttons, between last row of buttons and bottom, between first row of buttons and last field above
		 */
		static private var buttonGap:int;
		/**
		 * gap to be used between left side and any textfield, between textfield and right side, and between textfields
		 */
		static private var textGap:int;
		/**
		 *  if false then the selectedamount still has the value added by the app, based on fooditem database, not yet changed by user
		 */
		private var _defaultAmountOverwritten:Boolean = false;
		/**
		 *  if false then the selectedamount still has the value added by the app, based on fooditem database, not yet changed by user
		 */
		public function get defaultAmountOverwritten():Boolean
		{
			return _defaultAmountOverwritten;
		}
		/**
		 *  if false then the selectedamount still has the value added by the app, based on fooditem database, not yet changed by user
		 */
		public function set defaultAmountOverwritten(value:Boolean):void
		{
			_defaultAmountOverwritten = value;
		}
		
		
		//*********************
		// the button to add the fooditem to the list of selected items
		//*********************
		private var _add_button_text:String;

		public function get add_button_text():String
		{
			return _add_button_text;
		}

		public function set add_button_text(value:String):void
		{
			_add_button_text = value;
			if (add_button) {
				add_button.label = value;
				invalidateDisplayList();
			}
		}
		
		private var add_button:Button;
		
		private var _add_button_click_function:Function;
		
		/**
		 * the function that will be called when the button is clicked 
		 */
		public function get add_button_click_function():Function
		{
			return _add_button_click_function;
		}
		
		//*********************
		// the digit buttons
		//*********************
		private var button_0:Button;
		private var button_1:Button;
		private var button_2:Button;
		private var button_3:Button;
		private var button_4:Button;
		private var button_5:Button;
		private var button_6:Button;
		private var button_7:Button;
		private var button_8:Button;
		private var button_9:Button;
		private var button_DEL:Button;
		private var button_DecimalPoint:Button;

		
		/**
		 * @private
		 */
		public function set add_button_click_function(value:Function):void
		{
			_add_button_click_function = value;
			if (add_button) {
				add_button.addEventListener(MouseEvent.CLICK,_add_button_click_function);
			}
		}
		

		/**
		 * the width is set during updatedisplaylist, and used in measure
		 */
		private var _width:Number;
		/**
		 * the height is set during updatedisplaylist, and used in measure
		 */
		private var _height:Number;
		
		private var amountValidator:NumberValidator;
		
		/**
		 * constructor, nothing special about it, calls super 
		 */
		public function AddFoodItemGroup()
		{
			super();
			if (!buttonSizesKnown) {
				buttonMinimumWidth = styleManager.getStyleDeclaration(".addFoodItemGroup").getStyle("buttonMinimumWidth");
				buttonMaximumWidth = styleManager.getStyleDeclaration(".addFoodItemGroup").getStyle("buttonMaximumWidth");
				buttonMinimumHeight = styleManager.getStyleDeclaration(".addFoodItemGroup").getStyle("buttonMinimumHeight");
				buttonMaximumHeight = styleManager.getStyleDeclaration(".addFoodItemGroup").getStyle("buttonMaximumHeight");
				buttonGap = styleManager.getStyleDeclaration(".addFoodItemGroup").getStyle("buttonGap");
				textGap = styleManager.getStyleDeclaration(".addFoodItemGroup").getStyle("textGap");
			}
			amountValidator = new NumberValidator();
			amountValidator.allowNegative = false;
			amountValidator.source = amount_textinput;
			amountValidator.property = "text";
			amountValidator.domain="real"
			amountValidator.thousandsSeparator=".";
			amountValidator.separationError="";
		}
		
		/**
		 * sets measured width and height, also min values, based on stored values 
		 */
		override protected function measure():void {
			//super.measure();
			if (!_width)
				_width=0;
			if (!_height)
				_height=0;
			measuredHeight=this._height;
			measuredMinHeight=this._height;
			measuredWidth=this._width;
			measuredMinWidth=this._width;
		}
		
		override protected function updateDisplayList(containerWidth:Number, containerHeight:Number):void {
			//super.updateDisplayList(containerWidth,containerHeight);
		
			var oldwidth:Number = _width;
			var oldheight:Number = _height;
			_width=containerWidth;
			_height = 0;

			description_textarea.setLayoutBoundsSize(containerWidth - textGap * 2 ,ModelLocator.StyleableTextFieldCalculatedHeight);
			description_textarea.setLayoutBoundsPosition(textGap,ModelLocator.offSetSoThatTextIsInTheMiddle);
			_height = ModelLocator.StyleableTextFieldCalculatedHeight;
			
			var preferredButtonHeight:int = details_button.getPreferredBoundsHeight();
			details_button.setLayoutBoundsSize(containerWidth - textGap * 2,preferredButtonHeight);
			details_button.setLayoutBoundsPosition(textGap,_height);
			_height += preferredButtonHeight;
			
			_height += textGap;//juist adding some gap

			var preferredAmountTextAreaWidth:int = amount_textarea.getPreferredBoundsWidth();
			amount_textarea.setLayoutBoundsSize(preferredAmountTextAreaWidth,ModelLocator.StyleableTextFieldCalculatedHeight);
			amount_textarea.setLayoutBoundsPosition(textGap,_height + ModelLocator.offSetSoThatTextIsInTheMiddle);

			amount_textinput.setLayoutBoundsSize(containerWidth - textGap * 3 - preferredAmountTextAreaWidth,ModelLocator.StyleableTextFieldCalculatedHeight);
			amount_textinput.setLayoutBoundsPosition(textGap + preferredAmountTextAreaWidth + textGap,_height + ModelLocator.offSetSoThatTextIsInTheMiddle);
			_height += ModelLocator.StyleableTextFieldCalculatedHeight;

			_height += textGap;//juist adding some gap

			var preferredMealTextAreaWidth:int = meal_textarea.getPreferredBoundsWidth();
			meal_textarea.setLayoutBoundsSize(preferredMealTextAreaWidth,ModelLocator.StyleableTextFieldCalculatedHeight);
			meal_textarea.setLayoutBoundsPosition(textGap,_height 
				+ ModelLocator.offSetSoThatTextIsInTheMiddle + 
				/* to make sure the text of the textarea is nicely aligned with the text in the mealbutton */(preferredButtonHeight - ModelLocator.StyleableTextFieldCalculatedHeight)/2);
			
			meal_button.setLayoutBoundsSize(containerWidth - textGap * 3 - preferredMealTextAreaWidth,preferredButtonHeight);
			meal_button.setLayoutBoundsPosition(textGap + preferredMealTextAreaWidth + textGap,_height);
			_height += preferredButtonHeight;

			_height += textGap;//juist adding some gap
			
			var availableWidthForDigitButtons:int = Math.floor(containerWidth*0.7);
			var buttonHeight:int = Math.floor((containerHeight - _height - buttonGap * 4)/4);
			buttonHeight = Math.min(buttonHeight,buttonMaximumHeight);

			add_button.setLayoutBoundsSize(containerWidth - textGap * 2 - availableWidthForDigitButtons,buttonHeight);
			add_button.setLayoutBoundsPosition(availableWidthForDigitButtons + textGap ,_height);
			
			var buttonWidth:int = Math.floor((availableWidthForDigitButtons - buttonGap * 4)/3);
			buttonWidth = Math.min(buttonWidth,buttonMaximumWidth);
			var leftOffset:int = Math.floor((availableWidthForDigitButtons - 3 * buttonWidth - 2 * buttonGap)/2);
			
			if (button_0 == null) {
				button_0 = new Button();button_1 = new Button();button_2 = new Button();button_3 = new Button();button_4 = new Button();button_5 = new Button();
				button_6 = new Button();button_7 = new Button();button_8 = new Button();button_9 = new Button();button_DecimalPoint = new Button();button_DEL = new Button();
				
				//button_0.styleName = this;button_1.styleName = this;button_2.styleName = this;button_3.styleName = this;button_4.styleName = this;button_5.styleName = this;
				//button_6.styleName = this;button_7.styleName = this;button_8.styleName = this;button_9.styleName = this;button_DecimalPoint.styleName = this;button_DEL.styleName = this;
				
				button_0.label = "0";button_1.label = "1";button_2.label = "2";button_3.label = "3";button_4.label = "4";button_5.label = "5";
				button_6.label = "6";button_7.label = "7";button_8.label = "8";button_9.label = "9";button_DecimalPoint.label = ".";button_DEL.label = "<";
				
				addElement(button_0);addElement(button_1);addElement(button_2);addElement(button_3);addElement(button_4);addElement(button_5);
				addElement(button_6);addElement(button_7);addElement(button_8);addElement(button_9);addElement(button_DEL);addElement(button_DecimalPoint);
				
				button_0.addEventListener(MouseEvent.CLICK,digitButtonClicked);button_1.addEventListener(MouseEvent.CLICK,digitButtonClicked);button_2.addEventListener(MouseEvent.CLICK,digitButtonClicked);
				button_3.addEventListener(MouseEvent.CLICK,digitButtonClicked);button_4.addEventListener(MouseEvent.CLICK,digitButtonClicked);button_5.addEventListener(MouseEvent.CLICK,digitButtonClicked);
				button_6.addEventListener(MouseEvent.CLICK,digitButtonClicked);button_7.addEventListener(MouseEvent.CLICK,digitButtonClicked);button_8.addEventListener(MouseEvent.CLICK,digitButtonClicked);
				button_9.addEventListener(MouseEvent.CLICK,digitButtonClicked);button_DecimalPoint.addEventListener(MouseEvent.CLICK,digitButtonClicked);button_DEL.addEventListener(MouseEvent.CLICK,digitButtonClicked);
				
				button_0.setLayoutBoundsSize(buttonWidth, buttonHeight);button_1.setLayoutBoundsSize(buttonWidth, buttonHeight);button_2.setLayoutBoundsSize(buttonWidth, buttonHeight);button_3.setLayoutBoundsSize(buttonWidth, buttonHeight);
				button_4.setLayoutBoundsSize(buttonWidth, buttonHeight);button_5.setLayoutBoundsSize(buttonWidth, buttonHeight);button_6.setLayoutBoundsSize(buttonWidth, buttonHeight);button_7.setLayoutBoundsSize(buttonWidth, buttonHeight);
				button_8.setLayoutBoundsSize(buttonWidth, buttonHeight);button_9.setLayoutBoundsSize(buttonWidth, buttonHeight);button_DecimalPoint.setLayoutBoundsSize(buttonWidth, buttonHeight);button_DEL.setLayoutBoundsSize(buttonWidth, buttonHeight);
				
				button_1.setLayoutBoundsPosition(leftOffset ,_height);
				button_2.setLayoutBoundsPosition(leftOffset + buttonGap + buttonWidth,_height);
				button_3.setLayoutBoundsPosition(leftOffset + (buttonGap + buttonWidth)*2 ,_height);
				_height += buttonHeight + buttonGap  ;
				button_4.setLayoutBoundsPosition(leftOffset ,_height);
				button_5.setLayoutBoundsPosition(leftOffset + buttonGap + buttonWidth,_height);
				button_6.setLayoutBoundsPosition(leftOffset + (buttonGap + buttonWidth)*2 ,_height);
				_height += buttonHeight + buttonGap  ;
				button_7.setLayoutBoundsPosition(leftOffset ,_height);
				button_8.setLayoutBoundsPosition(leftOffset + buttonGap + buttonWidth,_height);
				button_9.setLayoutBoundsPosition(leftOffset + (buttonGap + buttonWidth)*2 ,_height);
				_height += buttonHeight + buttonGap  ;
				button_DecimalPoint.setLayoutBoundsPosition(leftOffset ,_height);
				button_0.setLayoutBoundsPosition(leftOffset + buttonGap + buttonWidth,_height);
				button_DEL.setLayoutBoundsPosition(leftOffset + (buttonGap + buttonWidth)*2 ,_height);
				_height += buttonHeight + buttonGap  ;
			} else {
				//we don't need to recreate all buttons because they already exist, but we do need to continue calculating _height
				//here I just repeated all increase of _height as done in case buttons are created
				_height += buttonHeight + buttonGap;
				_height += buttonHeight + buttonGap;
				_height += buttonHeight + buttonGap;
				_height += buttonHeight + buttonGap;  
			}
			
			if ((oldwidth != _width) || (oldheight != _height))
				invalidateSize();
		}
		
		private function digitButtonClicked(e:MouseEvent):void {
			if (!defaultAmountOverwritten) {
				defaultAmountOverwritten = true;
				amount_textinput_text = "";
			}
			var buttonText:String = (e.currentTarget as Button).label;
			if (buttonText == "<") {
				if (amount_textinput_text.length > 0)
					amount_textinput_text = amount_textinput_text.substring(0,amount_textinput_text.length - 1);
			} else if (buttonText == ".") {
				if (amount_textinput_text.indexOf(".") >= 0)
					return;//don't add any additional decimal point
				if (amount_textarea_text.length > 0)
					amount_textinput_text = amount_textinput_text + "."
			} else  {
				if (amount_textinput_text == "0")
					amount_textinput_text = buttonText;
				else
					amount_textinput_text += buttonText;
			}
			amountTextChangedFunction();
		}
		
		override protected function createChildren():void  {
			if (!description_textarea) {
				description_textarea = new StyleableTextField();
				description_textarea.styleName = this;
				description_textarea.editable = false;
				description_textarea.multiline = false;
				description_textarea.wordWrap = false;
				description_textarea.text = description_textarea_text;
				addElement(description_textarea);
			}
			if (!details_button) {
				details_button = new Button();
				details_button.styleName = this;
				//details_button.editable = false;
				//details_button.multiline = false;
				//details_button.wordWrap = false;
				details_button.label = details_button_text;
				if (_details_button_click_function != null)
					details_button.addEventListener(flash.events.MouseEvent.CLICK,_details_button_click_function);
				addElement(details_button);
			}
			if (!amount_textinput) {
				amount_textinput = new StyleableTextField();
				amount_textinput.styleName = this;
				amount_textinput.editable = false;
				amount_textinput.multiline = false;
				amount_textinput.wordWrap = false;
				amount_textinput.text = amount_textinput_text;
				//amount_textinput.setStyle("color","0x0B333C");
				addElement(amount_textinput);
			}
			if (!amount_textarea) {
				amount_textarea = new StyleableTextField();
				amount_textarea.styleName = this;
				amount_textarea.editable = false;
				amount_textarea.multiline = false;
				amount_textarea.wordWrap = false;
				amount_textarea.text = amount_textarea_text;
				addElement(amount_textarea);
			}
			if (!meal_textarea) {
				meal_textarea = new StyleableTextField();
				meal_textarea.styleName = this;
				meal_textarea.editable = false;
				meal_textarea.multiline = false;
				meal_textarea.wordWrap = false;
				meal_textarea.text = meal_textarea_text;
				addElement(meal_textarea);
			}
			if (!meal_button) {
				meal_button = new Button();
				meal_button.styleName = this;
				if (_meal_button_click_function != null)
					meal_button.addEventListener(MouseEvent.CLICK,_meal_button_click_function);
				//meal_button.editable = false;
				//meal_button.multiline = false;
				//meal_button.wordWrap = false;
				meal_button.label = meal_button_text;
				addElement(meal_button);
			}
			if (!add_button) {
				add_button = new Button();
				add_button.styleName = this;
				//add_button.editable = false;
				//add_button.multiline = false;
				//add_button.wordWrap = false;
				if (_add_button_click_function != null)
					add_button.addEventListener(MouseEvent.CLICK,_add_button_click_function);
				add_button.label = add_button_text;
				addElement(add_button);
			}
		}
		
	}
}