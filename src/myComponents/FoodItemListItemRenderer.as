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
	import databaseclasses.FoodItem;

	public class FoodItemListItemRenderer extends ListItemRenderer
		
	{
		/**
		 * itemHeight of an element as measured by default. Will be assigned intial value, so that we can reassign the correct value<br>
		 * see the code
		 */
		private static var defaultHeight:int=0;

		public function FoodItemListItemRenderer()
		{
			super();
		}

		override public function set data(value:Object):void {
			if (!(value as FoodItem).shownInList) {
				visible = false;
			}
			super.data = value;
		}
		
		override protected function measure():void  {
			super.measure();
			if (defaultHeight == 0)
				defaultHeight = measuredHeight;
			
			//Trace.myTrace("in fooditemlistitemrendere, fooditem = " + (data as FoodItem).itemDescription + ", showninlist = " + (data as FoodItem).shownInList + ", height = " + height);
			if (!(data as FoodItem).shownInList) {
				measuredHeight = 0;
				height = 0;
			} else {
				measuredHeight = defaultHeight;
				height = defaultHeight;	
			}
		}
	}
}