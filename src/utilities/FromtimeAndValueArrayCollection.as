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
	import mx.collections.ArrayCollection;
	
	import spark.collections.Sort;
	import spark.collections.SortField;
	
	/**
	 * Will hold a list of FromAndValueElements<br>
	 * Offers methods to get the Value for a specific timing (between 00:00 and maximum 36:00:00 = 129600 seconds)<br>
	 * 
	 * Such a list is either<br>
	 * <ul>
	 * 
	 * <li>percentage based<br>
	 * Starts always from 100 % and goes down to 0 %. It is not mandatory to specify the first and last element, these
	 * will be added automatically and will not be editable or deletable<br>
	 * The last element will be set to 129600 seconds = 36 hours<br>
	 * <br>
	 * When adding an item, the value will be checked with the value of the element before and after, it must be respectively smaller and greater than<br>
	 * When adding an element with a fromtime that already exists, then it will be overwrite the existing element.<br>
	 * Unit is %, and can't be modified
	 * </li>
	 * 
	 * <li>
	 * not percentage based<br>
	 * Any element can have any value<br>
	 * any unit, can be modified<br>
	 * When creating an list, there will always be one element with fromtime 00:00 and value 0, not deletable or editable<br>
	 * Runs till 24:00 only<br>
	 * </li>
	 * </ul>
	 */public class FromtimeAndValueArrayCollection extends ArrayCollection
	 {
		 private var _percentageBased:Boolean = false;
		 
		 public function get percentageBased():Boolean
		 {
			 return _percentageBased;
		 }
		 
		 private var _unit:String;
		 
		 public function get unit():String
		 {
			 return _unit;
		 }
		 
		 private var _arrayChanged:Boolean = false;
		 
		 /**
		  * is set to true whenever an item is added or removed, or when array is created<br>
		  * method is available to set the value to false, it is up to the client to use this method<br>
		  * 
		  */
		 public function get arrayChanged():Boolean
		 {
			 return _arrayChanged;
		 }
		 
		 /**
		  * as the name suggests, sets arrrayChanged to false
		  */
		 public function setArrayChangedToFalse():void {
			  _arrayChanged = false;
		  }
		 
		 
		 private var dataSortField:SortField = new SortField();
		 private var dataSort:Sort = new Sort();
		 
		 /**
		  * See comments on class itself to get more detals<br>
		  * if newUnit = %, means array will be percentage based
		  * 
		  */public function FromtimeAndValueArrayCollection(source:Array=null,newUnit:String = "")
		  {
			  super(source);
			  
			  _unit = newUnit;
			  if (_unit == "%")
				  _percentageBased = true;
			  
			  //check if element exists with from 00:00, if not add it
			  var cntr:int;
			  for (cntr = 0;cntr < length;cntr++) {
				  if ((getItemAt(cntr) as FromtimeAndValue).from == 0) {
					  break;
				  }
			  }
			  if (cntr == length) {
				  super.addItem(new FromtimeAndValue("00:00",percentageBased ? 100: 0,unit,percentageBased ? false:true,false));
			  }
			  
			  if (percentageBased) {
				  //check if element exists with from 36:00, if not add it
				  for (cntr = 0;cntr < length;cntr++) {
					  if ((getItemAt(cntr) as FromtimeAndValue).from == 129600) {
						  break;
					  }
				  }
				  if (cntr == length) {
					  super.addItem(new FromtimeAndValue(129600,0,unit,false,false));
				  }
			  }
			  
			  dataSortField.name="from";//value in FromtimeAndValue
			  dataSortField.numeric = true;
			  dataSort.fields = [dataSortField];
			  sort = dataSort;
			  refresh();
			  _arrayChanged = true;
		  }
		 
		 /**
		  * See comments on class itself to get more details<br>
		  * 
		  */override public function removeItemAt(index:int):Object {
			  if ((getItemAt(index) as FromtimeAndValue).from	== 0)
				  //we don't remove the first element
				  return (getItemAt(index));
			  if (percentageBased) {
				  if ((getItemAt(index) as FromtimeAndValue).from	== 129600)
					  //we don't remove the last element
					  return (getItemAt(index));
			  }
			  var returnValue:Object = super.removeItemAt(index);
			  _arrayChanged = true;
			  refresh();
			  return returnValue;
		  }
		 
		 /**
		  * See comments on class itself to get more details<br>
		  * when adding a FromtimeAndValue element, the unit is ignored because it will always be the unit of the fromtimeandvaluearraycollection that will be used.
		  * 
		  */override public function addItem(item:Object):void {
			  if (!(item is FromtimeAndValue))
				  throw new Error("can only add FromtimeAndValue objects to FromtimeAndValueArrayCollection");
			  //check if element with same fromtime already exists
			  var cntr:int;
			  
			  //verifications on values, if erros, Error is thrown
			  if (percentageBased)  {
				  if ((item as FromtimeAndValue).from == 0)
					  if ((item as FromtimeAndValue).value != 100)
						  throw new Error("percentage based fromtimeandvalue, you're trying to add an element with from = 00:00 and value different from 100, that's not allowed");
				  
				  if ((item as FromtimeAndValue).from == 129600 )
					  if ((item as FromtimeAndValue).value != 0)
						  throw new Error("percentage based fromtimeandvalue, you're trying to add an element with from = 36:00 and value different from 0, that's not allowed");
				  
				  var previousItem:int = 0;
				  while ((getItemAt(previousItem + 1) as FromtimeAndValue).from < (item as FromtimeAndValue).from && previousItem < length)
					  previousItem++;
				  if ((getItemAt(previousItem) as FromtimeAndValue).value < (item as FromtimeAndValue).value
					  ||
					  (getItemAt(previousItem + 1) as FromtimeAndValue).value > (item as FromtimeAndValue).value
				  )
					  throw new Error("percentage based fromtimeandvalue, you're trying to add an item with value that is not greater than or smaller than the previous or next element");
				  
				  if ((item as FromtimeAndValue).value > 100)
					  throw new Error("percentage based fromtimeandvalue, you're trying to add an item with value > 100");
			  }
			  if ((item as FromtimeAndValue).from > 129600)
				  throw new Error("fromtimeandvalue, you're trying to add an item with from > 129600");
			  
			  
			  //if any element exists with same fromtime, it is removed first
			  for (cntr = 0;cntr < length;cntr++) {
				  if ((getItemAt(cntr) as FromtimeAndValue).from == (item as FromtimeAndValue).from) {
					  super.removeItemAt(cntr);
					  break;
				  }
			  }
			  
			  //if percentage based, and if fromtime = 0 or 129600, then add it as not editable and not deletable
			  if (percentageBased) {
				  if ((item as FromtimeAndValue).from == 0) {
					  super.addItem(new FromtimeAndValue((item as FromtimeAndValue).from,(item as FromtimeAndValue).value,unit,false,false));
				  }
				  else if ((item as FromtimeAndValue).from == 129600) {
					  super.addItem(new FromtimeAndValue((item as FromtimeAndValue).from,(item as FromtimeAndValue).value,unit,false,false));
				  }
				  else
					  super.addItem(new FromtimeAndValue((item as FromtimeAndValue).from,(item as FromtimeAndValue).value,unit,(item as FromtimeAndValue).editable,(item as FromtimeAndValue).deletable)); 
			  } else if ((item as FromtimeAndValue).from == 0) {
				  super.addItem(new FromtimeAndValue((item as FromtimeAndValue).from,(item as FromtimeAndValue).value,unit,(item as FromtimeAndValue).editable,false));
			  } else {
				  super.addItem(new FromtimeAndValue((item as FromtimeAndValue).from,(item as FromtimeAndValue).value,unit,(item as FromtimeAndValue).editable,(item as FromtimeAndValue).deletable));
			  }
			  refresh();	
			  _arrayChanged = true;
		  }
		 
		 /**
		  * gets the value for a specific timing. For percentage based lists, linear interpolation will be applied 
		  * between the from before and after the specified fromTime<br>
		  * <br>
		  * fromTime can have one of three formats :
		  * <ul>
		  * <li>
		  * a string representation of a time between 00:00 and 36:00 otherwise an error is thrown
		  * </li>
		  * <li>
		  * a number representing time in seconds, between 0 and 129600
		  * </li>
		  * <li>
		  * a date object - in this case only the Hour of the Day and the Minutes will be taken into account<br>
		  * Which means, if a data object is used , the maximum value can be 23:59<br>
		  * This is treated as real date, new utc conversion or something like that.
		  * </li>
		  * </ul>
		  */public function getValue(fromTimeAsNumber:Number = Number.NaN,fromTimeAsString:String = "",fromTimeAsDate:Date = null):Number {
			  
			  if (!isNaN(fromTimeAsNumber)) {
				  if (fromTimeAsNumber > 129600)
					  throw new Error("fromTimeAsNumber should not be > 129600");
			  }
			  if (!fromTimeAsString == "") {
				  return getValue(((new Number(fromTimeAsString.split(":")[0])) * 60 + (new Number(fromTimeAsString.split(":")[1])))*60); 
			  }
			  
			  if (fromTimeAsDate != null) {
				  return getValue(((new Number(fromTimeAsDate.hours)) * 60 + (new Number(fromTimeAsDate.minutes)))*60); 
			  }
			  
			  var previousItem:int;
			  previousItem = 0;
			  
			  if (length == 1)
				  //it's definitely not a percentage based list, so no need to interpolate
				  return (getItemAt(0) as FromtimeAndValue).value;
			  
			  while (previousItem < length - 1 && (getItemAt(previousItem + 1) as FromtimeAndValue).from < fromTimeAsNumber)
				  previousItem++;
			  
			  var returnValue:Number;
			  if (percentageBased) {
				  var increase:Number = 
					  ( (getItemAt(previousItem + 1) as FromtimeAndValue).value - (getItemAt(previousItem) as FromtimeAndValue).value)
					  /
					  ( (getItemAt(previousItem + 1) as FromtimeAndValue).from - (getItemAt(previousItem) as FromtimeAndValue).from);
				  returnValue =  
					  (getItemAt(previousItem) as FromtimeAndValue).value 
					  + 
					  increase * (fromTimeAsNumber - (getItemAt(previousItem) as FromtimeAndValue).from);
			  } else
				  returnValue = (getItemAt(previousItem) as FromtimeAndValue).value;
			  
			  return returnValue;
		  }
		 
		 /**
		  * mmol/l-00:00>1.5  betekent correctiefactor 1.5 van 00:00 tot 23:59, eerste veld is de eenheid
		  * mg/dl-00:00>1.5-08:00>2.3-20:00>1.5 betekent 1.5 tussen 00:00 en 08:00 en 2.3 tussen 8 en 20 en vanaf 20 1.5
		  */public static function createList(correctionFactorListAsString:String):FromtimeAndValueArrayCollection {
			  var splittedByDash:Array = correctionFactorListAsString.split("-");
			  var unit:String = splittedByDash[0];
			  var returnValue:FromtimeAndValueArrayCollection = new FromtimeAndValueArrayCollection(null,unit);
			  for (var ctr:int = 1;ctr < splittedByDash.length;ctr++) {
				  returnValue.addItem( 
					  new FromtimeAndValue(
						  splittedByDash[ctr].split(">")[0],
						  splittedByDash[ctr].split(">")[1],
						  unit,
						  true,
						  true
					  )
				  );
			  }
			  return returnValue;
		  }
		 
		 /**
		 * just overriding it to align some comment<br>
		 * 
		 * using addItemAt does not really make sense because a sort will always occur<br>
		 * better to use addItem, then do getItemIndex to know the new index. 
		  */override public function addItemAt(newObject:Object,index:int):void {
			 return super.addItemAt(newObject,index);
		 }
		 
		 public function createCorrectionFactorAsString():String {
			 var returnValue:String = unit;
			 for (var cntr:int = 0;cntr < length;cntr++) {
				 returnValue += "-";
				 returnValue += (getItemAt(cntr) as FromtimeAndValue).fromAsString();
				 returnValue += ">";
				 returnValue += (getItemAt(cntr) as FromtimeAndValue).value.toString();
			 }
			 return returnValue;
		 }
	 }
}