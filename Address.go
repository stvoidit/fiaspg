package fiaspg

import (
	"encoding/xml"
	"io"

	"github.com/google/uuid"
)

// Address - ...
type Address struct {
	AOID       uuid.UUID `xml:"AOID,attr"`
	AOGUID     uuid.UUID `xml:"AOGUID,attr"`
	PARENTGUID uuid.UUID `xml:"PARENTGUID,attr"`
	NEXTID     uuid.UUID `xml:"NEXTID,attr"`
	PREVID     uuid.UUID `xml:"PREVID,attr"`
	FORMALNAME string    `xml:"FORMALNAME,attr"`
	OFFNAME    string    `xml:"OFFNAME,attr"`
	SHORTNAME  string    `xml:"SHORTNAME,attr"`
	AOLEVEL    uint64    `xml:"AOLEVEL,attr"`
	REGIONCODE uint64    `xml:"REGIONCODE,attr"`
	AREACODE   uint64    `xml:"AREACODE,attr"`
	AUTOCODE   uint64    `xml:"AUTOCODE,attr"`
	CITYCODE   uint64    `xml:"CITYCODE,attr"`
	CTARCODE   uint64    `xml:"CTARCODE,attr"`
	PLACECODE  uint64    `xml:"PLACECODE,attr"`
	PLAINCODE  string    `xml:"PLAINCODE,attr"`
	STREETCODE uint64    `xml:"STREETCODE,attr"`
	EXTRCODE   uint64    `xml:"EXTRCODE,attr"`
	SEXTCODE   uint64    `xml:"SEXTCODE,attr"`
	CODE       string    `xml:"CODE,attr"`
	CURRSTATUS uint64    `xml:"CURRSTATUS,attr"`
	ACTSTATUS  bool      `xml:"ACTSTATUS,attr"`
	LIVESTATUS bool      `xml:"LIVESTATUS,attr"`
	CENTSTATUS uint64    `xml:"CENTSTATUS,attr"`
	OPERSTATUS uint64    `xml:"OPERSTATUS,attr"`
	OKATO      string    `xml:"OKATO,attr"`
	OKTMO      string    `xml:"OKTMO,attr"`
	POSTALCODE string    `xml:"POSTALCODE,attr"`
	DIVTYPE    uint64    `xml:"DIVTYPE,attr"`
	PLANCODE   uint64    `xml:"PLANCODE,attr"`
}

// AddressesDecoder - ...
type AddressesDecoder struct {
	wrchan chan Address
	r      io.Reader
}

// NewAddrDecoder - ...
func NewAddrDecoder(r io.Reader) *AddressesDecoder {
	return &AddressesDecoder{
		wrchan: make(chan Address),
		r:      r}
}

// Next - ...
func (ad *AddressesDecoder) Next() <-chan Address {
	decoder := xml.NewDecoder(ad.r)
	go func() {
		for {
			token, err := decoder.Token()
			if token == nil || err == io.EOF {
				break
			} else if err != nil {
				panic(err)
			}
			var adr Address
			switch ty := token.(type) {
			case xml.StartElement:
				if ty.Name.Local == "Object" {
					if err := decoder.DecodeElement(&adr, &ty); err != nil {
						panic(err)
					}
					ad.wrchan <- adr
				}
			}
		}
		close(ad.wrchan)
	}()
	return ad.wrchan
}
