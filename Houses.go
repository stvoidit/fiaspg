package fiaspg

import (
	"encoding/xml"
	"io"

	"github.com/google/uuid"
)

// House - ...
type House struct {
	HOUSEID    uuid.UUID `xml:"HOUSEID,attr"`
	HOUSEGUID  uuid.UUID `xml:"HOUSEGUID,attr"`
	AOGUID     uuid.UUID `xml:"AOGUID,attr"`
	STRUCNUM   string    `xml:"STRUCNUM,attr"`
	BUILDNUM   string    `xml:"BUILDNUM,attr"`
	HOUSENUM   string    `xml:"HOUSENUM,attr"`
	STRSTATUS  uint64    `xml:"STRSTATUS,attr"`
	ESTSTATUS  uint64    `xml:"ESTSTATUS,attr"`
	STATSTATUS uint64    `xml:"STATSTATUS,attr"`
	OKATO      string    `xml:"OKATO,attr"`
	OKTMO      string    `xml:"OKTMO,attr"`
	POSTALCODE uint64    `xml:"POSTALCODE,attr"`
	DIVTYPE    uint64    `xml:"DIVTYPE,attr"`
	REGIONCODE uint64    `xml:"REGIONCODE,attr"`
	CADNUM     string    `xml:"CADNUM,attr"`
}

// HousesDecoder - ...
type HousesDecoder struct {
	wrchan chan House
	r      io.Reader
}

// NewHousesDecoder - ...
func NewHousesDecoder(r io.Reader) *HousesDecoder {
	return &HousesDecoder{
		wrchan: make(chan House),
		r:      r}
}

// Next - ...
func (hd *HousesDecoder) Next() <-chan House {
	decoder := xml.NewDecoder(hd.r)
	go func() {
		for {
			token, err := decoder.Token()
			if token == nil || err == io.EOF {
				break
			} else if err != nil {
				panic(err)
			}
			var h House
			switch ty := token.(type) {
			case xml.StartElement:
				if ty.Name.Local == "House" {
					if err := decoder.DecodeElement(&h, &ty); err != nil {
						panic(err)
					}
					hd.wrchan <- h
				}
			}
		}
		close(hd.wrchan)
	}()
	return hd.wrchan
}
