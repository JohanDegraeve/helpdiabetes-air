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
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.graphics.BitmapFillMode;
	
	import spark.components.Image;
	import spark.components.LabelItemRenderer;
	
	import utilities.FromtimeAndValue;
	
	/**
	 * 
	 */
	public class FromtimeAndValueItemRenderer extends LabelItemRenderer
	{
		private var editImage:Image;//Pencil-icon48x48
		[Embed(source="assets/edit48x48.png")]
		[Bindable]
		public var editIcon:Class;

		private var deleteImage:Image;
		[Embed(source="assets/Trash_48x48.png")]
		[Bindable]
		public var deleteIcon:Class;
		
		private var addImage:Image;
		[Embed(source="assets/add48x48.png")]
		[Bindable]
		public var addIcon:Class;
		
		/**
		 * to dispatch event data delete button as clicked
		 */public static var DELETE_CLICKED:String = "FROMTIME_AND_VALUE_ITEMRENDERER_DELETE_CLICKED";
		
		/**
		 * to dispatch event data edit button as clicked
		 */public static var EDIT_CLICKED:String = "FROMTIME_AND_VALUE_ITEMRENDERER_EDIT_CLICKED";
		
		/**
		 * to dispatch event data add button as clicked
		 */public static var ADD_CLICKED:String = "FROMTIME_AND_VALUE_ITEMRENDERER_ADD_CLICKED";
		
		private var _editable:Boolean = false;

		private function get editable():Boolean
		{
			return _editable;
		}

		private function set editable(value:Boolean):void
		{
			_editable = value;
			if (!editImage && _editable) {
				editImage = new Image();
				editImage.fillMode = BitmapFillMode.CLIP;
				editImage.source = editIcon;
				editImage.addEventListener(MouseEvent.CLICK,editClicked);
				addChild(editImage);
			}
		}
		
		private var _deletable:Boolean = false;

		private function get deletable():Boolean
		{
			return _deletable;
		}

		private function set deletable(value:Boolean):void
		{
			_deletable = value;
			if (!deleteImage && _deletable) {
				deleteImage = new Image();
				deleteImage.fillMode = BitmapFillMode.CLIP;
				deleteImage.source = deleteIcon;
				deleteImage.addEventListener(MouseEvent.CLICK,deleteClicked);
				addChild(deleteImage);
			}
		}
		
		private var _elementCanBeAdded:Boolean = false;
		
		private function get elementCanBeAdded():Boolean
		{
			return _elementCanBeAdded;
		}
		
		private function set elementCanBeAdded(value:Boolean):void
		{
			_elementCanBeAdded = value;
			if (!addImage && _elementCanBeAdded) {
				addImage = new Image();
				addImage.fillMode = BitmapFillMode.CLIP;
				addImage.source = addIcon;
				addImage.addEventListener(MouseEvent.CLICK,addClicked);
				addChild(addImage);
			}
		}
		
		private function deleteClicked(event:Event):void {
			this.dispatchEvent(new Event(DELETE_CLICKED,true,true));
		}
		
		private function editClicked(event:Event):void {
			this.dispatchEvent(new Event(EDIT_CLICKED,true,true));
		}
		
		private function addClicked(event:Event):void {
			this.dispatchEvent(new Event(ADD_CLICKED,true,true));
		}

		static private var ITEM_HEIGHT:int = 48;
		static private var ICON_WIDTH:int = 48;
		static private var offsetToPutTextInTheMiddle:int;
		
		public function FromtimeAndValueItemRenderer()
		{
			super();
			if (offsetToPutTextInTheMiddle == 0)
				offsetToPutTextInTheMiddle = styleManager.getStyleDeclaration(".trackingItems").getStyle("offsetToPutTextInTheMiddle");
 		}
		
		/**
		 * @private
		 *
		 * Override this setter to respond to data changes
		 */
		override public function set data(value:Object):void
		{
			super.data = value;
			if (value == null)
				return;
			var theDataAsFromToAndValue:FromtimeAndValue = value as FromtimeAndValue;
			label = 
				theDataAsFromToAndValue.fromAsString() 
				+ " "
				+ (Math.round(theDataAsFromToAndValue.value) == theDataAsFromToAndValue.value ?
					theDataAsFromToAndValue.value
					:
					(Math.round((theDataAsFromToAndValue.value * 10)) / 10).toString())
				+ " "
				+ theDataAsFromToAndValue.unit;
			deletable = theDataAsFromToAndValue.deletable;
			editable = theDataAsFromToAndValue.editable;
			elementCanBeAdded = theDataAsFromToAndValue.unit == "%" ?
									(theDataAsFromToAndValue.from == 86400 || theDataAsFromToAndValue.from == (86400 - 60))  ? false:true
									:
									(theDataAsFromToAndValue.from ==  86400 || theDataAsFromToAndValue.from == (86400 - 60))? false:true;
		} 
		
		/**
		 * @private
		 * 
		 * Override this method to change how the item renderer 
		 * sizes itself. For performance reasons, do not call 
		 * super.measure() unless you need to.
		 */ 
		override protected function measure():void
		{
			super.measure();
			// measure all the subcomponents here and set measuredWidth, measuredHeight, 
			// measuredMinWidth, and measuredMinHeight      		
		}
		
		/**
		 * @private
		 * 
		 * Override this method to change how the background is drawn for 
		 * item renderer.  For performance reasons, do not call 
		 * super.drawBackground() if you do not need to.
		 */
		override protected function drawBackground(unscaledWidth:Number, 
												   unscaledHeight:Number):void
		{
			//only draw a border line
			graphics.lineStyle(1, 0, 0.75);
			graphics.moveTo(0,unscaledHeight - 1);
			graphics.lineTo(unscaledWidth,unscaledHeight - 1);
			graphics.endFill();
		}
		
		/**
		 * @private
		 *  
		 * Override this method to change how the background is drawn for this 
		 * item renderer. For performance reasons, do not call 
		 * super.layoutContents() if you do not need to.
		 */
		override protected function layoutContents(unscaledWidth:Number, 
												   unscaledHeight:Number):void
		{
			//super.layoutContents(unscaledWidth, unscaledHeight);
			if (editImage) {
				setElementSize(editImage,ICON_WIDTH,ITEM_HEIGHT);
				setElementPosition(editImage,unscaledWidth - ICON_WIDTH,0);
			}
			if (addImage) {
				setElementSize(addImage,ICON_WIDTH,ITEM_HEIGHT);
				setElementPosition(addImage,unscaledWidth - ICON_WIDTH - (editImage?ICON_WIDTH:0),0); 
			}
			if (deleteImage) {
				setElementSize(deleteImage,ICON_WIDTH,ITEM_HEIGHT);
				setElementPosition(deleteImage,unscaledWidth - ICON_WIDTH - (editImage?ICON_WIDTH:0) - (addImage?ICON_WIDTH:0),0); 
			}
			setElementSize(labelDisplay,unscaledWidth - ICON_WIDTH *2 ,ITEM_HEIGHT);
			setElementPosition(labelDisplay,0,offsetToPutTextInTheMiddle);
		}
	}
}