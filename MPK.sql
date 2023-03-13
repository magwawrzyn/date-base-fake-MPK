-- !preview conn=DBI::dbConnect(RSQLite::SQLite())
DROP TABLE Wykaz_sluzb CASCADE;
DROP TABLE Wykaz_linii CASCADE;
DROP TABLE Kierowcy CASCADE;
DROP TABLE Place CASCADE;
DROP TABLE Pojazdy CASCADE;



---- DEFINICJE TABEL

CREATE TABLE Wykaz_linii(
	Brygada INTEGER NOT NULL CHECK (Brygada BETWEEN 10001 AND 99999),
	Czas_pracy INTERVAL NOT NULL CHECK (Czas_pracy BETWEEN '00:01:00' AND '10:30:00'),
	PRIMARY KEY (Brygada)
);
CREATE TABLE Pojazdy(
	Nr_pojazdu INTEGER NOT NULL CHECK (Nr_pojazdu BETWEEN 1000 AND 9999),
	Marka VARCHAR(15) NOT NULL,
	Czy_sprawny BOOLEAN DEFAULT TRUE,
	PRIMARY KEY (NR_pojazdu)
);
CREATE TABLE Place(
	Prog INTEGER NOT NULL,
	Stawka_podstawowa INTEGER NOT NULL,
	Stawka_za_nadgodziny INTEGER NOT NULL,
	PRIMARY KEY (Prog)
);
CREATE TABLE Kierowcy(
	ID SERIAL NOT NULL,
	Imie VARCHAR(15) NOT NULL,
	Nazwisko VARCHAR(30) NOT NULL,
	PESEL VARCHAR(11) NOT NULL UNIQUE CHECK (length(PESEL) = 11),
	Czy_aktywny BOOLEAN DEFAULT TRUE,
	Prog_placowy INTEGER DEFAULT 1 REFERENCES Place(Prog),
	PRIMARY KEY (ID)
);
CREATE TABLE Wykaz_sluzb(
	Brygada INTEGER NOT NULL REFERENCES Wykaz_linii(Brygada),
	ID_kierowcy INTEGER NOT NULL REFERENCES Kierowcy(ID),
	Nr_pojazdu INTEGER NOT NULL REFERENCES Pojazdy(Nr_pojazdu),
	Data_sluzby DATE NOT NULL,
	PRIMARY KEY (ID_kierowcy, Data_sluzby)
);


---- SEKCJA WYZWALACZY

-- wyzwalacz sprawdzajacy poprawnosc PESEL

CREATE OR REPLACE FUNCTION 
	sprawdzenie_pesel() 
RETURNS TRIGGER AS $$
DECLARE spr BIGINT;
BEGIN
	SELECT
	CAST (NEW.PESEL AS BIGINT) INTO spr;
	RETURN NEW;
EXCEPTION
	WHEN others THEN 
		RAISE INFO 'Zly PESEL';
	RETURN NULL;
END;
$$ LANGUAGE 'plpgsql';
DROP TRIGGER sprawdzenie_pesel_trigger ON Kierowcy CASCADE;
CREATE TRIGGER sprawdzenie_pesel_trigger BEFORE INSERT OR UPDATE ON Kierowcy
FOR EACH ROW EXECUTE PROCEDURE sprawdzenie_pesel();


-- wyzwalacz sprawdzajacy, czy jest spelniony wymog max 90h pracy w ostatnim tyg.
-- sprawdzenie przy dodawaniu nowej sluzby (lub zmianie obecnej)

CREATE OR REPLACE FUNCTION 
	sprawdzenie_90h() 
RETURNS TRIGGER AS $$
DECLARE suma_godzin INTERVAL; nowy_czas_pracy INTERVAL;
BEGIN
	SELECT sum(Czas_pracy) INTO suma_godzin FROM(
	SELECT Brygada, Czas_pracy FROM Wykaz_sluzb JOIN Wykaz_linii USING(Brygada)
	WHERE ID_kierowcy=NEW.ID_kierowcy 
	AND Data_sluzby>(NEW.Data_sluzby::TIMESTAMP - interval '1 day' * 7)) AS inn_select;
	SELECT Czas_pracy::INTERVAL INTO nowy_czas_pracy FROM Wykaz_linii
	WHERE Brygada=NEW.Brygada;
	IF (suma_godzin + nowy_czas_pracy > '120:00:00') THEN 
		RAISE INFO 'Przekroczony dopuszczalny czas pracy!';
		RETURN NULL;
	ELSE
		RETURN NEW;
	END IF;
	
END;
$$ LANGUAGE 'plpgsql';
DROP TRIGGER sprawdzenie_90h_trigger ON Wykaz_sluzb CASCADE;
CREATE TRIGGER sprawdzenie_90h_trigger BEFORE INSERT OR UPDATE ON Wykaz_sluzb
FOR EACH ROW EXECUTE PROCEDURE sprawdzenie_90h();

-- wyzwalacz sprawdzajacy, czy na danej brygadzie, danego dnia, juz ktos nie jezdzi,
-- sprawdzenie przy dodawaniu nowej sluzby (lub zmianie obecnej)
CREATE OR REPLACE FUNCTION 
	sprawdzenie_obsadzenia() 
RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.Brygada IN 
		(SELECT Brygada FROM Wykaz_sluzb WHERE Data_sluzby=NEW.Data_sluzby)) 
	THEN
		RAISE INFO 'Ktos juz jezdzi na tej brygadzie!';
		RETURN NULL;
	ELSE
		RETURN NEW;
	END IF;
END;
$$ LANGUAGE 'plpgsql';
DROP TRIGGER sprawdzenie_obsadzenia_trigger ON Wykaz_sluzb CASCADE;
CREATE TRIGGER sprawdzenie_obsadzenia_trigger BEFORE INSERT OR UPDATE ON Wykaz_sluzb
FOR EACH ROW EXECUTE PROCEDURE sprawdzenie_obsadzenia();

-- wyzwalacz ktory sprawdza, czy dany autobus danego dnia jest wolny
-- mozliwe 2 przypadki, gdy zadziala: 1) woz juz zajety, 2) woz nie jest sprawny ( czyli zostal skreslony z ilostanu)
CREATE OR REPLACE FUNCTION 
	sprawdzenie_wozu() 
RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.Nr_pojazdu IN 
		((SELECT Nr_Pojazdu FROM Wykaz_sluzb WHERE Data_sluzby=NEW.Data_sluzby) UNION
		(SELECT Nr_pojazdu FROM Pojazdy WHERE Czy_sprawny=FALSE)))
	THEN
		RAISE INFO 'Zly wybor pojazdu - prosze zmienic woz!';
		RETURN NULL;
	ELSE
		RETURN NEW;
	END IF;
END;
$$ LANGUAGE 'plpgsql';
DROP TRIGGER sprawdzenie_wozu_trigger ON Wykaz_sluzb CASCADE;
CREATE TRIGGER sprawdzenie_wozu_trigger BEFORE INSERT OR UPDATE ON Wykaz_sluzb
FOR EACH ROW EXECUTE PROCEDURE sprawdzenie_wozu();

-- wyzwalacz sprawdzajacy, czy dany kierowca jest aktywnym pracownikiem firmy
CREATE OR REPLACE FUNCTION 
	sprawdzenie_czy_aktywny() 
RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.ID_kierowcy IN
		(SELECT ID FROM Kierowcy WHERE Czy_aktywny=FALSE))
	THEN
		RAISE INFO 'Ten kierowca nie jest aktywnym pracownikiem firmy!';
		RETURN NULL;
	ELSE
		RETURN NEW;
	END IF;
END;
$$ LANGUAGE 'plpgsql';
DROP TRIGGER sprawdzenie_czy_aktywny_trigger ON Wykaz_sluzb CASCADE;
CREATE TRIGGER sprawdzenie_czy_aktywny_trigger BEFORE INSERT OR UPDATE ON Wykaz_sluzb
FOR EACH ROW EXECUTE PROCEDURE sprawdzenie_czy_aktywny();



---- SEKCJA WIDOKOW

-- widok ktory wyswietla wynagrodzenia miesieczne po ID kierowcy
-- korzysta z widoku pomocniczego

DROP VIEW miesieczny_czas_pracy;
CREATE OR REPLACE VIEW miesieczny_czas_pracy AS(
	SELECT to_char(Data_sluzby,'YYYY-MM') AS Rok_miesiac, ID_kierowcy, 
	CASE
	WHEN sum(Czas_pracy)<='168:00:00' THEN sum(Czas_pracy)
	ELSE
	'168:00:00'
	END AS Msc_suma_godzin,
	CASE 
	WHEN sum(Czas_pracy)>'168:00:00' THEN EXTRACT(epoch FROM (sum(Czas_pracy)-'168:00:00')/3600)
	ELSE
	0
	END AS Nadgodziny
	FROM Wykaz_sluzb
	JOIN Wykaz_linii USING(Brygada)
	GROUP BY to_char(Data_sluzby,'YYYY-MM'), ID_kierowcy
	ORDER BY ID_kierowcy
);



DROP VIEW miesieczne_wynagrodzenia;
CREATE OR REPLACE VIEW miesieczne_wynagrodzenia AS(
	SELECT Rok_miesiac, ID_kierowcy, Imie, Nazwisko, (Stawka_podstawowa+nadgodziny*Stawka_za_nadgodziny)::INTEGER AS Wyplata
	FROM miesieczny_czas_pracy M
	JOIN Kierowcy ON(M.ID_kierowcy = Kierowcy.ID)
	JOIN Place ON(Kierowcy.Prog_placowy=Place.Prog)
	GROUP BY Rok_miesiac, ID_kierowcy, Imie, Nazwisko, Stawka_podstawowa+nadgodziny*Stawka_za_nadgodziny
	ORDER BY ID_kierowcy
);


---- SEKCJA POTRZEBNYCH FUNKCJI

--KIEROWCY
--zatrudnij kierowce
CREATE OR REPLACE FUNCTION
	zatrudnij_kierowce(Imiek VARCHAR(15), Nazwiskok VARCHAR (30), PESELk VARCHAR(11))
RETURNS VOID AS $$
BEGIN
	IF (PESELk IN (SELECT PESEL FROM Kierowcy)) 
	THEN
		UPDATE Kierowcy SET Czy_aktywny=TRUE
		WHERE PESEL = PESELk;
	ELSE
		INSERT INTO Kierowcy(Imie,Nazwisko,PESEL) VALUES (Imiek,Nazwiskok,PESELk);
	END IF;
	
END;
$$ LANGUAGE 'plpgsql';

--zwolnij kierowce
CREATE OR REPLACE FUNCTION
	zwolnij_kierowce(ID_zwalnianego INTEGER)
RETURNS VOID AS $$
BEGIN
	UPDATE Kierowcy SET Czy_aktywny=FALSE 
	WHERE ID=ID_zwalnianego;
END;
$$ LANGUAGE 'plpgsql';

--zmien prog placowy kierowcy
CREATE OR REPLACE FUNCTION
	zmien_prog(ID_K INTEGER, Nowy_prog INTEGER)
RETURNS VOID AS $$
BEGIN
	UPDATE Kierowcy SET Prog_placowy=Nowy_prog WHERE ID=ID_K;
END;
$$ LANGUAGE 'plpgsql';

--POJAZDY
--dodaj nowy pojazd
CREATE OR REPLACE FUNCTION
	dodaj_pojazd(Nr_poj INTEGER, Markapoj VARCHAR(15))
RETURNS VOID AS $$
BEGIN
	INSERT INTO Pojazdy(Nr_pojazdu,Marka) VALUES (Nr_poj,Markapoj);
END;
$$ LANGUAGE 'plpgsql';

--przeznacz pojazd do kasacji
CREATE OR REPLACE FUNCTION
	skasuj_pojazd(Nr_poj INTEGER)
RETURNS VOID AS $$
BEGIN
	UPDATE Pojazdy SET Czy_sprawny=FALSE WHERE Nr_pojazdu=Nr_poj;
END;
$$ LANGUAGE 'plpgsql';

--WYKAZ SLUZB
--dodaj sluzbe
CREATE OR REPLACE FUNCTION
	dodaj_sluzbe(Jaka_brygada INTEGER,ID_K INTEGER,Woz INTEGER,Dzien DATE)
RETURNS VOID AS $$
BEGIN
	INSERT INTO Wykaz_sluzb(Brygada,ID_kierowcy,Nr_pojazdu,Data_sluzby)
	VALUES(Jaka_brygada,ID_K,Woz,Dzien);
END;
$$ LANGUAGE 'plpgsql';

--zmien sluzbe
CREATE OR REPLACE FUNCTION 
	zmien_sluzbe(ID_K INTEGER, Dzien DATE, Brygada_new INTEGER, Woz_new INTEGER)
RETURNS VOID AS $$
BEGIN
	IF (Dzien>=current_date::DATE) 
	THEN
		UPDATE Wykaz_sluzb SET Brygada=Brygada_new, Nr_pojazdu=Woz_new
		WHERE ID_kierowcy=ID_K AND Data_sluzby=Dzien;
	ELSE
		RAISE EXCEPTION 'Nie mozna zmienic odbytych sluzb!';
	END IF;
END;
$$ LANGUAGE 'plpgsql';

--znajdz sluzby kierowcy
CREATE OR REPLACE FUNCTION
	znajdz_sluzby_kierowcy(ID_K INTEGER, Data_od DATE, Data_do DATE)
RETURNS TABLE(
	BrygadaA INTEGER,
	Data_sluzbyA DATE,
	Nr_pojazduA INTEGER)	 
AS $$
BEGIN
	RETURN QUERY
	SELECT Brygada, Data_sluzby, Nr_pojazdu FROM Wykaz_sluzb
	WHERE ID_kierowcy=ID_K AND (Data_sluzby BETWEEN Data_od AND Data_do);
END;
$$ LANGUAGE 'plpgsql';

--znajdz, kto danego dnia jezdzil na danej linii
CREATE OR REPLACE FUNCTION
	znajdz_kto_na_linii(Nr_linii INTEGER, Dzien DATE)
RETURNS TABLE(
	LiniaA INTEGER,
	ID_kierowcyA INTEGER,
	ImieA VARCHAR(15),
	NazwiskoA VARCHAR (15))	 
AS $$
BEGIN
	RETURN QUERY
	SELECT (Brygada/100)::INTEGER AS Linia, ID_kierowcy, Imie, Nazwisko
	FROM Wykaz_sluzb JOIN Kierowcy ON(Wykaz_sluzb.ID_kierowcy=Kierowcy.ID)
	WHERE Data_sluzby=Dzien AND ((Brygada/100)::INTEGER)=Nr_linii;
END;
$$ LANGUAGE 'plpgsql';
