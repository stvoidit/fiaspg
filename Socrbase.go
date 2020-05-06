package fiaspg

import (
	"encoding/xml"
	"io"
)

// Socrbase - ...
type Socrbase struct {
	LEVEL    string `xml:"LEVEL,attr"`
	SOCRNAME string `xml:"SOCRNAME,attr"`
	SCNAME   string `xml:"SCNAME,attr"`
	KODTST   string `xml:"KOD_T_ST,attr"`
}

// SocrbaseDecoder - ...
type SocrbaseDecoder struct {
	wrchan chan Socrbase
	r      io.Reader
}

// NewSocrbaseDecoder - ...
func NewSocrbaseDecoder(r io.Reader) *SocrbaseDecoder {
	return &SocrbaseDecoder{
		wrchan: make(chan Socrbase),
		r:      r}
}

// Next - ...
func (sb *SocrbaseDecoder) Next() <-chan Socrbase {
	decoder := xml.NewDecoder(sb.r)
	go func() {
		for {
			token, err := decoder.Token()
			if token == nil || err == io.EOF {
				break
			} else if err != nil {
				panic(err)
			}
			var s Socrbase
			switch ty := token.(type) {
			case xml.StartElement:
				if ty.Name.Local == "AddressObjectType" {
					if err := decoder.DecodeElement(&s, &ty); err != nil {
						panic(err)
					}
					sb.wrchan <- s
				}
			}
		}
		close(sb.wrchan)
	}()
	return sb.wrchan
}
