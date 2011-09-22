package myComponents
{
	import model.ModelLocator;
	
	import spark.components.Button;
	import spark.components.DataGroup;
	import spark.components.Group;
	import spark.components.supportClasses.GroupBase;
	import spark.components.supportClasses.StyleableTextField;
	
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
		
		public function get details_button_text():String
		{
			return _details_button_text;
		}

		public function set details_button_text(value:String):void
		{
			_details_button_text = value;
			if (details_button) {
				details_button.label = value;
				invalidateDisplayList();
			}
		}
		
		private var details_button:Button;

		//*********************
		// amount entered by the user, can be editable in case buttons are not used
		//*********************
		private var _amount_textinput_text:String;

		public function get amount_textinput_text():String
		{
			return _amount_textinput_text;
		}

		public function set amount_textinput_text(value:String):void
		{
			_amount_textinput_text = value;
			if (amount_textinput) {
				amount_textinput.text = value;
				invalidateDisplayList();
			}
		}
		
		private var amount_textinput:StyleableTextField;

		//*********************
		// the static text saying meal...
		//*********************
		private var _meal_textarea_text:String;

		public function get meal_textarea_text():String
		{
			return _meal_textarea_text;
		}

		public function set meal_textarea_text(value:String):void
		{
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
			_meal_button_text = value;
			if (meal_button) {
				meal_button.label = value;
				invalidateDisplayList();
			}
		}
		
		private var meal_button:Button;
		
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
		
		/**
		 * the width is set during updatedisplaylist, and used in measure
		 */
		private var _width:Number;
		/**
		 * the height is set during updatedisplaylist, and used in measure
		 */
		private var _height:Number;
		
		/**
		 * constructor, nothing special about it, calls super 
		 */
		public function AddFoodItemGroup()
		{
			super();
			
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

			description_textarea.setLayoutBoundsSize(containerWidth,ModelLocator.StyleableTextFieldHeight);
			description_textarea.setLayoutBoundsPosition(0,0);
			_height = ModelLocator.StyleableTextFieldHeight;
			
			details_button.setLayoutBoundsSize(containerWidth,ModelLocator.StyleableTextFieldHeight);
			details_button.setLayoutBoundsPosition(0,_height);
			_height += ModelLocator.StyleableTextFieldHeight;

			amount_textarea.setLayoutBoundsSize(containerWidth,ModelLocator.StyleableTextFieldHeight);
			amount_textarea.setLayoutBoundsPosition(0,_height);
			_height += ModelLocator.StyleableTextFieldHeight;

			amount_textinput.setLayoutBoundsSize(containerWidth,ModelLocator.StyleableTextFieldHeight);
			amount_textinput.setLayoutBoundsPosition(0,_height);
			_height += ModelLocator.StyleableTextFieldHeight;
			
			meal_textarea.setLayoutBoundsSize(containerWidth,ModelLocator.StyleableTextFieldHeight);
			meal_textarea.setLayoutBoundsPosition(0,_height);
			_height += ModelLocator.StyleableTextFieldHeight;
			
			meal_button.setLayoutBoundsSize(containerWidth,ModelLocator.StyleableTextFieldHeight);
			meal_button.setLayoutBoundsPosition(0,_height);
			_height += ModelLocator.StyleableTextFieldHeight;
			
			add_button.setLayoutBoundsSize(containerWidth,ModelLocator.StyleableTextFieldHeight);
			add_button.setLayoutBoundsPosition(0,_height);
			_height += ModelLocator.StyleableTextFieldHeight +30;
			
			if ((oldwidth != _width) || (oldheight != _height))
				invalidateSize();
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
				addElement(details_button);
			}
			if (!amount_textinput) {
				amount_textinput = new StyleableTextField();
				amount_textinput.styleName = this;
				amount_textinput.editable = false;
				amount_textinput.multiline = false;
				amount_textinput.wordWrap = false;
				amount_textinput.text = amount_textinput_text;
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
				add_button.label = add_button_text;
				addElement(add_button);
			}
		}
		
	}
}