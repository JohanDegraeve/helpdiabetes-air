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
package utilities
{
	import databaseclasses.FoodItem;
	
	import model.ModelLocator;
	
	import mx.collections.ArrayCollection;
	
	import spark.collections.Sort;
	import spark.collections.SortField;

	public class ExcelSorting
	{
		
		/**
		 * Array used for comparing char values according to Excel rules.<br>
		 * Element at index x, has the same value as in column 'Considered Equal to' in the table above, <br>
		 * for the row with Ascii code x.<br>
		 * The last element has value '256', this is the value that will be used for any character which char-value out of range <br>
		 */
		 private static var CHARORDER:Array = [  0,   1,  2,  3,  4,  5,  6,  7,  8,  40,
			41,  42, 43, 44, 9,  10, 11, 12, 13, 14,
			15,  16, 17, 18, 19, 20, 21, 22, 23, 24,
			25,  26, 38, 45, 46, 47, 48, 49, 50, 33,
			51,  52, 53, 88, 54, 34, 55, 56,115,120,
			122,124,125,126,127,128,129,130, 57, 58,
			89,  90, 91, 59, 60,147,149,153,157,167,
			170,172,174,184,186,188,190,192,196,213,
			215,217,219,224,229,239,241,243,245,251,
			255, 61, 62, 63, 64, 66, 67,147,149,153,
			157,167,170,172,174,184,186,188,190,192,
			196,213,215,217,219,224,229,239,241,243,
			245,251,255, 68, 69, 70, 71, 27,114, 28,
			82 ,170, 85,112,109,110, 65,113,224, 86,
			213, 29,255, 30, 31, 80, 81, 83, 84,111,
			36,  37, 79,229,224, 87,213, 32,255,251,
			39,  72, 97, 98, 99,100, 73,101, 74,102,
			147, 93,103, 35,104, 75,105, 92,122,124,
			76, 106,107,108, 77,120,213, 94,116,117,
			118, 78,147,147,147,147,147,147,147,153,
			167,167,167,167,184,184,184,184,157,196,
			213,213,213,213,213, 95,213,239,239,239,
			239,251,229,224,147,147,147,147,147,147,
			147,153,167,167,167,167,184,184,184,184,
			157,196,213,213,213,213,213, 96,213,239,
			239,239,239,251,229,251,256];
		
		 private var previousSearchString:String = null;
		 private var firstIndex:Array;
		 private var lastIndex:Array;
		 private var _foodItemList:ArrayCollection;
		 private var sortField:SortField;
		 private var sort:Sort;

		 public function get foodItemList():ArrayCollection

		 {
			 return _foodItemList;
		 }
		 		 
		/**
		 * if foodItemList == null then an empty arraycollection will be created 
		 */
		 public function ExcelSorting(newFoodItemList:ArrayCollection = null)
		{
			firstIndex = new Array(ModelLocator.maximumSearchStringLength);
			lastIndex = new Array(ModelLocator.maximumSearchStringLength);
			firstIndex[0] = 0;
			if (newFoodItemList == null)
				_foodItemList = new ArrayCollection();
			else
				_foodItemList = newFoodItemList;
			sortField = new SortField();
			sortField.name = "itemDescription"
			sortField.compareFunction = compareFoodItemDescriptions;
			sort = new Sort();
			sort.fields = [sortField];
			newFoodItemList.sort = sort;
		}
		 
		public static function compareFoodItemDescriptions(a:Object,b:Object):int {
			//var returnvalue:int = compareStrings((a as FoodItem).itemDescription,(b as FoodItem).itemDescription);
			return compareStrings((a as FoodItem).itemDescription,(b as FoodItem).itemDescription);
		}
				
		/**
		 * Compares two characters <br>
		 * If both characters have uint value < 255, then Excel sorting rules are applied<br>
		 * Otherwise simple compare of the uint value is returned.
		 * @param characterA the first character to be compared to  <br>
		 * @param characterB the second character<br>
		 * @return the value 0 if characterA is equal to characterB; <br>
		 * 	a value less than 0 if characterA is numerically less than characterB; <br>
		 * 	and a value greater than 0 if characterB is numerically greater than characterA.<br> 
		 * 	Note that this is a comparison of the value in column 3 (considered equal to) in the table above.<br>
		 * 
		 */
		static public  function compareToAsInExcel( characterA:uint,  characterB:uint):int {
			if (characterA > (CHARORDER.length) || characterB > (CHARORDER.length))
				return characterA == characterB ? 0 : characterA < characterB ? -1 : 1;
				
			if (characterA > (CHARORDER.length - 1))//-1 because the very last element is not really considered to be a character value 
				characterA = CHARORDER[CHARORDER.length - 1];
			if (characterB > (CHARORDER.length - 1))//-1 because the very last element is not really considered to be a character value 
				characterB = CHARORDER[CHARORDER.length - 1];
			
			if (CHARORDER[characterA] < CHARORDER[characterB]) return -1;
			if (CHARORDER[characterA] > CHARORDER[characterB]) return 1;
			return 0;
		}
		
		public function getFirstMatchingItem(s:String):int {
			var index:int = 0;//index to first character that should be searched for
			var result:Array = [0,0];			
			
			lastIndex[0] = this._foodItemList.length -1; 
			
			/**
			 * first of all check if previousSearchString contains anything and if
			 * yes then calculate index at which searching should start. 
			 */
			if (previousSearchString != null) {
				while ((index < s.length) &&
					(index < previousSearchString.length) &&
					(compareToAsInExcel(s.charCodeAt(index), previousSearchString.charCodeAt(index)) == 0)) { 
					index++;
				}
			}
			
			/**
			 * now continue searching if necessary
			 */
			if (index == s.length) {
				//no need to search any further, firstIndex has the value to be returned, return will happen later
			} else {
				while ((index < s.length) && (index < (firstIndex.length - 1))) {
					result = searchFirst(firstIndex[index], lastIndex[index], s.charCodeAt(index), index);
					if (result[0] > -1) {
						firstIndex[index + 1] = result[0];
						lastIndex[index + 1] = searchLast(result[0], result[1], s.charCodeAt(index), index);
					} else {
						//nothing matching found
						if (index < (firstIndex.length - 1)) {
							firstIndex[index + 1] = firstIndex[index];
							lastIndex[index + 1] = lastIndex[index];
						}
					}
					index++;
				}
			}
			
			/**
			 * wrapping up
			 */
			previousSearchString = s.toString();
			return firstIndex[index];
		}
		
		/**
		 * Search the index of the first item 'matching' the char value. low is the index
		 * of the item in de fooditemlist where searching should start, high is the last.<br>
		 * index is the index to be used in the itemdescription String, in other words it 
		 * points to the character in the strings (searchstring and itemdescription strings) that
		 * is compared.<br>
		 * @param low
		 * @param high
		 * @param value
		 * @param index
		 * @return array of two elements of int, first one giving the actual result, second element is to be used in
		 * the call to searchlast that should normally be done immediately after searchfirst. If the first element < -2
		 * then nothing is found.
		 */
		private function searchFirst ( low:int,  high:int,  value:int, index:int):Array {
			var temp:int = 0;
			var temp2:int = 0;
			var mid:int = 0;
			var belength:int;
			low++;//doing this because i copied this code from my J2ME version, where I use recordstore and where the first record is stored in index = 1
			high++;
			//returnvalue [1] wil be set in this method to lowest value where a character was found with value > value.
			//this value will then be used when calling searchlast to reduce searching time
			var returnvalue:Array = [-1,high];
			
			var be:String;
			temp = high + 1;//this becomes the highest start value
			while (low < temp) {
				mid = (low + temp)/2;
				be = ((this._foodItemList.getItemAt(mid-1)) as FoodItem).itemDescription;
				belength = be.length;
				if (!(belength > index))//b is a string which is shorter than the enteredstring, so definitely before the enteredstring (smaller than)
				{low = mid+1;}
				else {
					if (compareToAsInExcel(be.charCodeAt(index), value) < 0)
						low = mid + 1; 
					else {
						if (temp2 > value) {
							returnvalue[1] = mid;
						} 
						temp = mid; 
					}     
				}
				
			}
			if (low > high) {
				
			} else {
				be = ((this._foodItemList.getItemAt(low-1)) as FoodItem).itemDescription;
				belength = be.length;
				if (belength > index) {
					if ((low < (high + 1)) && (compareToAsInExcel(be.charCodeAt(index), value) == 0))
						returnvalue[0] = low;
				} else {
					;
				}
			}
			returnvalue[0] = returnvalue[0] -1; 
			returnvalue[1] = returnvalue[1] -1; 
			return returnvalue;
		}
		
		/**
		 * For a full description see {@link #searchFirst(int, int, char, int) searchfirst}
		 * @param low
		 * @param high
		 * @param value
		 * @param index
		 * @return the result in theory it can happen that returnvalue = -1 however if searchFirst has been called
		 * this should not happen.
		 */
		private function searchLast ( low:int,  high:int,  value:int, index:int):int  {
			var  temp:int = 0;
			var  mid:int = 0;
			var  returnvalue:int = -1;
			var be:String;
			var  belength:int;
			
			low++;//doing this because i copied this code from my J2ME version, where I use recordstore and where the first record is stored in index = 1
			high++;
			temp = low -1;
			while (high > temp) {
				if ((high + temp)%2 > 0) {mid = (high+temp)/2+1;}
				else {mid = (high+temp)/2;}
				be = ((this._foodItemList.getItemAt(mid-1)) as FoodItem).itemDescription;
				belength = be.length;
				if (!(belength > index))//be is a string which is shorter than the enteredstring, so definitely before the enteredstring (smaller than)
				{temp = mid;}
				else {
					if (compareToAsInExcel(be.charCodeAt(index), value) > 0)
						high = mid - 1; 
					else
						//can't be high = mid-1: here A[mid] >= value,
						//so high can't be < mid if A[mid] == value
						temp = mid; 
				}
				
			}
			if (high < low) {
				//returnvalue = -1;
			} else {
				be = ((this._foodItemList.getItemAt(high-1)) as FoodItem).itemDescription;
				belength = be.length;
				if (belength > index) {
					if (((low-1) < high) && (compareToAsInExcel(be.charCodeAt(index), value) == 0))
						returnvalue = high;
				} else {
					;//returnvalue = -1;
				}
			}    
			returnvalue= returnvalue -1; 
			return returnvalue;
		}
		
		/**
		 * compares the strings according to excel rules <br>
		 * returns -1 if stringA comes before stringB<br>
		 * returns 0 if appear on same level (not necessarily equal, eg a = A<br>
		 * returns 1 if stringA comes after string B
		 * 
		 **/
		static public function compareStrings ( stringA:String ,stringB:String):int {
			//trace("in comparestrings, stringA =  " + stringA + " and stringB = " + stringB);
			var returnvalue:int = 0;
			var index:int = 0;
			
			var thisItemDescription:Array = stringToUint(stringA); 
			var itemDescriptionToCompare:Array = stringToUint(stringB); 
			
			while ((index < thisItemDescription.length) && 
				(index < itemDescriptionToCompare.length)) {
				if (ExcelSorting.compareToAsInExcel(thisItemDescription[index], itemDescriptionToCompare[index]) != 0) {
					break;
				}
				index++;	
			}
			if ((index < stringA.length) && 
				(index < itemDescriptionToCompare.length)) {
				if (ExcelSorting.compareToAsInExcel(thisItemDescription[index], itemDescriptionToCompare[index]) < 0)
					return -1;
				if (ExcelSorting.compareToAsInExcel(thisItemDescription[index], itemDescriptionToCompare[index]) > 0) 
					return 1;
			}
			//for sure thisItemDescription[index] = ItemDescriptionToCompare[index]
			//now it could still be that the lengths are different, we much be checked
			if ((index >= stringA.length) || 
				(index >= itemDescriptionToCompare.length)) {
				if (thisItemDescription.length < itemDescriptionToCompare.length) return -1;
				if (thisItemDescription.length > itemDescriptionToCompare.length) return  1;
			}
			return returnvalue;
		}

		static private function stringToUint(input:String):Array {
			var returnvalue:Array = new Array();
			for (var i:int = 0;i < input.length; i++)
				returnvalue.push(input.charCodeAt(i));
			return returnvalue;
		}
		
		/**
		 * returns true if stringB is within stringA 
		 */
		static public function stringAhasStringB(stringA:String, stringB:String):Boolean {
			if (stringB.length > stringA.length)
				return false;
			for (var i:int = 0;i <= stringA.length - stringB.length;i++) {
				if (compareStrings(stringA.substr(i,stringB.length),stringB) == 0)
					return true;
			}
			return false;
		}
	}
}