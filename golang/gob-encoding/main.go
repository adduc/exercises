package main

import (
	"bytes"
	"encoding/gob"
	"os"
)

type SampleStruct struct {
	String string
	Int    int
	Float  float64
	Bool   bool
	Struct EmbeddedStruct
}

type EmbeddedStruct struct {
	String string
	Int    int
}

func main() {
	sampleStruct := createSampleStruct()

	encodedData, err := encodeSampleStruct(sampleStruct)
	if err != nil {
		panic(err)
	}

	err = writeEncodedDataToFile(encodedData, "sample.gob")
	if err != nil {
		panic(err)
	}

	encodedDataFromFile, err := readEncodedDataFromFile("sample.gob")
	if err != nil {
		panic(err)
	}

	decodedStruct, err := decodeSampleStruct(encodedDataFromFile)
	if err != nil {
		panic(err)
	}

	if compareSampleStructs(sampleStruct, decodedStruct) {
		println("Structs are equal (expected)")
	} else {
		println("Structs are not equal")
	}

	sampleStruct.String = "asdfasdf"

	if compareSampleStructs(sampleStruct, decodedStruct) {
		println("Structs are equal")
	} else {
		println("Structs are not equal (expected)")
	}
}

func createSampleStruct() SampleStruct {
	return SampleStruct{
		String: "string",
		Int:    1,
		Float:  1.1,
		Bool:   true,
		Struct: EmbeddedStruct{
			String: "embedded string",
			Int:    2,
		},
	}
}

func encodeSampleStruct(s SampleStruct) ([]byte, error) {
	var buf bytes.Buffer
	enc := gob.NewEncoder(&buf)
	err := enc.Encode(s)
	if err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}

func writeEncodedDataToFile(data []byte, filename string) error {
	file, err := os.Create(filename)
	if err != nil {
		return err
	}
	defer file.Close()

	_, err = file.Write(data)
	if err != nil {
		return err
	}

	return nil
}

func readEncodedDataFromFile(filename string) ([]byte, error) {
	file, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	fileInfo, err := file.Stat()
	if err != nil {
		return nil, err
	}

	data := make([]byte, fileInfo.Size())
	_, err = file.Read(data)
	if err != nil {
		return nil, err
	}

	return data, nil
}

func decodeSampleStruct(data []byte) (SampleStruct, error) {
	var s SampleStruct
	dec := gob.NewDecoder(bytes.NewReader(data))
	err := dec.Decode(&s)
	if err != nil {
		return SampleStruct{}, err
	}
	return s, nil
}

func compareSampleStructs(s1, s2 SampleStruct) bool {
	return s1 == s2
}
