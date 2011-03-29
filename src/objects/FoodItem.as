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
			unitList = new ArrayCollection();

			this.itemDescription = foodItemDescription;
			
			for (var i:int = 0;i < units.length; i++) {
				var unitToAdd:Unit = units.getItemAt(i) as Unit;
				unitList.addItem(new Unit(unitToAdd.getDescription(),unitToAdd.getWeight(),unitToAdd.getStandardAmount(),unitToAdd.getKcal(),unitToAdd.getProtein(),unitToAdd.getCarbs(),unitToAdd.getFat()));
				unitList.addItem(unitToAdd);
			}
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
			return compareItemDescriptionTo (foodItemToCompare.itemDescription);
		}
		
		/**
		 * compares the strings according to excel rules 
		 **/
		public function compareItemDescriptionTo ( itemDescriptionToCompareString:String):int {
			var returnvalue:int = 0;
			var index:int = 0;
			
			var thisItemDescription:Array = stringToUint(itemDescription); 
			var itemDescriptionToCompare:Array = stringToUint(itemDescriptionToCompareString); 
			
			while ((index < thisItemDescription.length) && 
				(index < itemDescriptionToCompare.length)) {
				if (ExcelSorting.compareToAsInExcel(thisItemDescription[index], itemDescriptionToCompare[index]) != 0) {
					break;
				}
				index++;	
			}
			if ((index < itemDescription.length) && 
				(index < itemDescriptionToCompare.length)) {
				if (ExcelSorting.compareToAsInExcel(thisItemDescription[index], itemDescriptionToCompare[index]) < 0)
					return -1;
				if (ExcelSorting.compareToAsInExcel(thisItemDescription[index], itemDescriptionToCompare[index]) > 0) 
					return 1;
			}
			//for sure thisItemDescription[index] = ItemDescriptionToCompare[index]
			//now it could still be that the lengths are different, we much be checked
			if ((index >= itemDescription.length) || 
				(index >= itemDescriptionToCompare.length)) {
				if (thisItemDescription.length < itemDescriptionToCompare.length) return -1;
				if (thisItemDescription.length > itemDescriptionToCompare.length) return  1;
			}
			return returnvalue;
		}

		public function getNumberOfUnits():int {
			return unitList.length;
		}
		
		private function stringToUint(input:String):Array {
			var returnvalue:Array = new Array();
			for (var i:int = 0;i < input.length; i++)
				returnvalue.push(input.charCodeAt(i));
			return returnvalue;
		}
		
		

	}
}