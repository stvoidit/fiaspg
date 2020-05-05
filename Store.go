package fiaspg

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v4"
)

// DB - ...
type DB struct {
	conn *pgx.Conn
}

// NewStore - ...
func NewStore(host, port, login, password, dbname string) (*DB, error) {
	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable statement_cache_mode=prepare",
		host, port, login, password, dbname)
	config, err := pgx.ParseConfig(connStr)
	if err != nil {
		return nil, err
	}
	conn, err := pgx.ConnectConfig(context.Background(), config)
	if err != nil {
		return nil, err
	}
	return &DB{conn}, nil
}

// InsertAddresses - добавление адреса
func (db *DB) InsertAddresses(adrs ...Address) {
	const q = `INSERT
    INTO
    addresses (
        aoid 			--1
        , aoguid 		--2
        , parentguid	--3
        , nextid 		--4
        , previd 		--5
        , formalname 	--6
        , offname 		--7
        , shortname 	--8
        , aolevel 		--9
        , regioncode 	--10
        , areacode 		--11
        , autocode 		--12
        , citycode  	--13
        , ctarcode 		--14
        , placecode 	--15
        , streetcode 	--16
        , extracode 	--17
        , sextcode 		--18
        , plaincode 	--19
        , code 			--20
        , curstatus 	--21
        , actstatus 	--22
        , livestatus 	--23
        , centstatus 	--24
        , operstatus 	--25
        , okato 		--26
        , oktmo 		--27
        , postalcode 	--28
		, divtype 		--29
		, plancode 		--30
    )
	VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30);`
	var b = new(pgx.Batch)
	for _, adr := range adrs {
		b.Queue(q,
			adr.AOID,       // 1
			adr.AOGUID,     // 2
			adr.PARENTGUID, // 3
			adr.NEXTID,     // 4
			adr.PREVID,     // 5
			adr.FORMALNAME, // 6
			adr.OFFNAME,    // 7
			adr.SHORTNAME,  // 8
			adr.AOLEVEL,    // 9
			adr.REGIONCODE, // 10
			adr.AREACODE,   // 11
			adr.AUTOCODE,   // 12
			adr.CITYCODE,   // 13
			adr.CTARCODE,   // 14
			adr.PLACECODE,  // 15
			adr.STREETCODE, // 16
			adr.EXTRCODE,   // 17
			adr.SEXTCODE,   // 18
			adr.PLAINCODE,  // 19
			adr.CODE,       // 20
			adr.CURRSTATUS, // 21
			adr.ACTSTATUS,  // 22
			adr.LIVESTATUS, // 23
			adr.CENTSTATUS, // 24
			adr.OPERSTATUS, // 25
			adr.OKATO,      // 26
			adr.OKTMO,      // 27
			adr.POSTALCODE, // 28
			adr.DIVTYPE,    // 29
			adr.PLANCODE,   // 30
		)
	}
	result := db.conn.SendBatch(context.Background(), b)
	if _, err := result.Exec(); err != nil {
		panic(err)
	}
	result.Close()
}

// InsertHouses - ...
func (db *DB) InsertHouses(houses ...House) {
	const q = `INSERT
    INTO
    houses (
        houseid
        , houseguid
        , aoguid
        , structnum
        , buildnum
        , housenum
        , strstatus
        , eststatus
        , statstatus
        , okato
        , oktmo
        , postalcode
        , divtype
        , regioncode
        , cadnum
    )
	VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)`
	var b = new(pgx.Batch)
	for _, h := range houses {
		b.Queue(q,
			h.HOUSEID,
			h.HOUSEGUID,
			h.AOGUID,
			nullString(h.STRUCNUM),
			nullString(h.BUILDNUM),
			nullString(h.HOUSENUM),
			h.STRSTATUS,
			h.ESTSTATUS,
			h.STATSTATUS,
			h.OKATO,
			h.OKTMO,
			h.POSTALCODE,
			h.DIVTYPE,
			h.REGIONCODE,
			nullString(h.CADNUM),
		)
	}
	result := db.conn.SendBatch(context.Background(), b)
	if _, err := result.Exec(); err != nil {
		panic(err)
	}
	result.Close()
}

func nullString(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}
