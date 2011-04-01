package objects
{
	import mx.collections.ArrayCollection;
	
	import utilities.ExcelSorting;
	
	public class FoodItem
	{
		private var itemDescription:String;
		
		private var unitList:ArrayCollection;
		
		/**
		 * expects an array of units
		 */
		public function FoodItem(foodItemDescription:String, units:ArrayCollection) {
			unitList = units;
			this.itemDescription = foodItemDescription;
		}
		
		public function getItemDescription():String {
			return itemDescription;
		}
		
		public function setItemDescription(itemDescription:String):void {
			this.itemDescription = itemDescription;
		}
		
		public function getUnit(location:int):Unit {
			return unitList.getItemAt(location) as Unit;
		}
		
		public function addUnit(newUnit:Unit):void {
			unitList.addItem(newUnit);
		}
		
		/**
		 * compares the itemdescriptions according to excel rules 
		 **/
		public function compareTo(foodItemToCompare:FoodItem):int {
			return ExcelSorting.compareStrings(this.itemDescription,foodItemToCompare.itemDescription);
		}
		

		public function getNumberOfUnits():int {
			return unitList.length;
		}
		

	}
}