/*
Copyright IBM Corp. 2016 All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

		 http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package main

//WARNING - this chaincode's ID is hard-coded in chaincode_example04 to illustrate one way of
//calling chaincode from a chaincode. If this example is modified, chaincode_example04.go has
//to be modified as well with the new ID of chaincode_example02.
//chaincode_example05 show's how chaincode ID can be passed in as a parameter instead of
//hard-coding.

import (
	"encoding/json"
	"fmt"
	"strconv"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

// SimpleChaincode example simple Chaincode implementation
type SimpleChaincode struct {
}

// Merchant Struct
type Merchant struct {
	Name  string `json:"Name"`
	Asset string `json:"Asset"`
}

func row_keys_of_Merchant(merchant *Merchant) []string {
	return []string{merchant.Name}
}

//create merchant
func write(stub shim.ChaincodeStubInterface, merchant *Merchant) error {

	// Create composite key
	compositeKey, err := stub.CreateCompositeKey("Merchant", row_keys_of_Merchant(merchant))
	if err != nil {
		err = fmt.Errorf("stub.CreateCompositeKey failed with error")
	}

	// Marshal data
	bytes, err := json.Marshal(merchant)
	if err != nil {
		err = fmt.Errorf("InsertTableRow failed because json.Marshal failed with error %v", err)
		return err
	}

	// Store the data in the ledger state
	err = stub.PutState(compositeKey, bytes)
	if err != nil {
		err = fmt.Errorf("InsertTableRow failed because stub.PutState(%v) failed with error %v", compositeKey, err)
		return err
	}

	return nil //success
}

//get merchant
func read(stub shim.ChaincodeStubInterface, name string) (*Merchant, error) {

	merchant := new(Merchant)
	compositeKey, err := stub.CreateCompositeKey("Merchant", []string{name})
	if err != nil {
		return nil, fmt.Errorf("stub.CreateCompositeKey failed with error %s", err.Error())
	}

	var bytes []byte
	bytes, err = stub.GetState(compositeKey)
	if err != nil {
		return nil, fmt.Errorf("Failed to get state with error %s", err.Error())
	}

	err = json.Unmarshal(bytes, merchant)
	if err != nil {
		err = fmt.Errorf("query failed because json.Unmarshal failed with error %v", err)
		return nil, err
	}
	return merchant, nil
}

func (t *SimpleChaincode) Init(stub shim.ChaincodeStubInterface) pb.Response {
	fmt.Println("ex02 Init")
	_, args := stub.GetFunctionAndParameters()
	var A, B string    // Entities
	var Aval, Bval int // Asset holdings
	var err error

	if len(args) != 4 {
		return shim.Error("Incorrect number of arguments. Expecting 4")
	}

	// Initialize the chaincode
	A = args[0]
	Aval, err = strconv.Atoi(args[1])
	if err != nil {
		return shim.Error("Expecting integer value for asset holding")
	}
	B = args[2]
	Bval, err = strconv.Atoi(args[3])
	if err != nil {
		return shim.Error("Expecting integer value for asset holding")
	}
	fmt.Printf("Aval = %d, Bval = %d\n", Aval, Bval)

	// Write the state to the ledger
	err = write(stub, &Merchant{Name: A, Asset: strconv.Itoa(Aval)})
	if err != nil {
		return shim.Error(err.Error())
	}

	err = write(stub, &Merchant{Name: B, Asset: strconv.Itoa(Bval)})
	if err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success(nil)
}

func (t *SimpleChaincode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	fmt.Println("ex02 Invoke")
	function, args := stub.GetFunctionAndParameters()
	if function == "invoke" {
		// Make payment of X units from A to B
		return t.invoke(stub, args)
	} else if function == "delete" {
		// Deletes an entity from its state
		return t.delete(stub, args)
	} else if function == "query" {
		// the old "Query" is now implemtned in invoke
		return t.query(stub, args)
	}

	return shim.Error("Invalid invoke function name. Expecting \"invoke\" \"delete\" \"query\"")
}

// Transaction makes payment of X units from A to B
func (t *SimpleChaincode) invoke(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var A, B string    // Entities
	var Aval, Bval int // Asset holdings
	var X int          // Transaction value
	var err error

	if len(args) != 3 {
		return shim.Error("Incorrect number of arguments. Expecting 3")
	}

	A = args[0]
	B = args[1]

	// Get the state from the ledger
	// TODO: will be nice to have a GetAllState call to ledger
	merchantA, err := read(stub, A)
	if err != nil {
		return shim.Error(fmt.Sprintf("Failed to get state", err.Error()))
	}

	Aval, _ = strconv.Atoi(string(merchantA.Asset))

	merchantB, err := read(stub, B)
	if err != nil {
		return shim.Error("Failed to get state")
	}
	Bval, _ = strconv.Atoi(string(merchantB.Asset))

	// Perform the execution
	X, err = strconv.Atoi(args[2])
	if err != nil {
		return shim.Error("Invalid transaction amount, expecting a integer value")
	}
	Aval = Aval - X
	Bval = Bval + X
	fmt.Printf("Aval = %d, Bval = %d\n", Aval, Bval)

	// Write the state back to the ledger
	err = write(stub, &Merchant{Name: A, Asset: strconv.Itoa(Aval)})
	if err != nil {
		return shim.Error(err.Error())
	}

	err = write(stub, &Merchant{Name: B, Asset: strconv.Itoa(Bval)})
	if err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success(nil)
}

// Deletes an entity from state
func (t *SimpleChaincode) delete(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	A := args[0]

	// Create composite key
	compositeKey, err := stub.CreateCompositeKey("Merchant", []string{A})
	if err != nil {
		err = fmt.Errorf("stub.CreateCompositeKey failed with error")
	}

	// Delete the key from the state in ledger
	err = stub.DelState(compositeKey)
	if err != nil {
		return shim.Error("Failed to delete state")
	}

	return shim.Success(nil)
}

// query callback representing the query of a chaincode
func (t *SimpleChaincode) query(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var A string // Entities
	var err error

	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting name of the person to query")
	}

	A = args[0]

	// Get the state from the ledger
	merchantA, err := read(stub, A)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to get state for " + A + "\"}"
		return shim.Error(jsonResp)
	}

	jsonResp := "{\"Name\":\"" + A + "\",\"Amount\":\"" + merchantA.Asset + "\"}"
	fmt.Printf("Query Response:%s\n", jsonResp)
	return shim.Success([]byte(merchantA.Asset))
}

func main() {
	err := shim.Start(new(SimpleChaincode))
	if err != nil {
		fmt.Printf("Error starting Simple chaincode: %s", err)
	}
}
