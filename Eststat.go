package fiaspg

import (
	"encoding/xml"
	"io"
)

// EstateStatus - ...
type EstateStatus struct {
	ESTSTATID string `xml:"ESTSTATID,attr"`
	NAME      string `xml:"NAME,attr"`
	SHORTNAME string `xml:"SHORTNAME,attr"`
}

// EstateStatusDecoder - ...
type EstateStatusDecoder struct {
	wrchan chan EstateStatus
	r      io.Reader
}

// NewEstateStatusDecoder - ...
func NewEstateStatusDecoder(r io.Reader) *EstateStatusDecoder {
	return &EstateStatusDecoder{
		wrchan: make(chan EstateStatus),
		r:      r}
}

// Next - ...
func (sb *EstateStatusDecoder) Next() <-chan EstateStatus {
	decoder := xml.NewDecoder(sb.r)
	go func() {
		for {
			token, err := decoder.Token()
			if token == nil || err == io.EOF {
				break
			} else if err != nil {
				panic(err)
			}
			var es EstateStatus
			switch ty := token.(type) {
			case xml.StartElement:
				if ty.Name.Local == "EstateStatus" {
					if err := decoder.DecodeElement(&es, &ty); err != nil {
						panic(err)
					}
					sb.wrchan <- es
				}
			}
		}
		close(sb.wrchan)
	}()
	return sb.wrchan
}
