USE [Database]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-------------------------------------------------PROCEDURE D'INSERTION DES ETATS DE CONTROLE POOL TPV TPM DANS LE MODULE MERCURE DE PRODUCTION

SELECT * FROM Etat_Controle
ORDER BY Code_Etat_Controle DESC

SELECT * FROM Etat_Controle_Do
ORDER BY Code_Etat_Controle DESC

----------CREATION DES ETATS DANS LA TABLE ETAT DE CONTROLE PAR GODWIN 06/02/2023
----

SELECT * INTO Etat_Controle_Do
FROM Etat_Controle
WHERE Code_Etat_Controle IN ('022','021','020')

UPDATE Etat_Controle_Do
SET Code_Etat_Controle='023', Libelle_Etat_Controle='Emissions Pool TPV-TPM', Definition_Etat='etatemissionspool.rtm', Numero_Ordre=Numero_Ordre+3
WHERE Code_Etat_Controle='020'

UPDATE Etat_Controle_Do
SET Code_Etat_Controle='024', Libelle_Etat_Controle='Sinistres Pool TPV', Definition_Etat='etatsinistrestpv.rtm', Numero_Ordre=Numero_Ordre+3
WHERE Code_Etat_Controle='021'

UPDATE Etat_Controle_Do
SET Code_Etat_Controle='025', Libelle_Etat_Controle='Sinistres Pool TPM', Definition_Etat='etatsinistrestpm.rtm', Numero_Ordre=Numero_Ordre+3
WHERE Code_Etat_Controle='022'

INSERT INTO Etat_Controle
SELECT * FROM Etat_Controle_Do



-------------DEBUT MAJ PROCEDURE Edition_Controle_SpecifiqueSP PAR GODWIN 06/02/2023

USE [Mercure_1]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER                 Procedure [dbo].[Edition_Controle_SpecifiqueSP]
@Code_Etat_Controle 	Char(3),
@Date_1 		Datetime,
@Date_2 		Datetime

As

---- EMISSIONS POOL TPV TPM AJOUT PAR GODWIN 06/02/2023

If @Code_Etat_Controle='023' 

Select @Date_1,@Date_2
------
Select Distinct Libelle_Intermediaire as Point_Souscription,Q.Numero_Police ,Q.Numero_Avenant,Libelle_Mouvement as Type_Avenant,
Libelle_Categorie as Genre_Vehicule,Nom_Assure,Convert(Varchar,Date_Emission,103)as Date_Emission,Convert(Varchar,Date_Effet,103)as Date_Effet,Convert(Varchar,
Date_Expiration,103)as Date_Expiration,G.Numero_Immatriculation,Libelle_Energie as Energie,
Charge_Utile,Puissance_Administrative as Puissance_Fiscale,Nombre_Place,Gc.Prime_Nette as Prime_CEDEAO,
G.Prime_Nette as Prime_RC
From Quittance Q
Join Detail_Quittance DQ On (DQ.Numero_Quittance=Q.Numero_Quittance) 
Join Intermediaire I On (I.Code_Intermediaire=LEFT(Q.Numero_Quittance,4))
Join	(Select Ga.Numero_Reference,Q.Numero_Quittance,Ga.Numero_Immatriculation,Ga.Code_Categorie,Ga.Code_Sous_Garantie,
			(Case when Code_Mouvement in ('ANL') then Ga.Prime_Nette*-1 else Ga.Prime_Nette end) as Prime_nette  ---- Lire toutes les immatriculations et leur prime RC
		From Quittance Q
		Join Detail_Quittance DQ On (DQ.Numero_Quittance=Q.Numero_Quittance) 
		Join Garanties_Automobile Ga on Ga.Numero_Reference=Q.Numero_Reference
		Where Code_Sous_Garantie ='00002'
		--And SUBSTRING (Numero_Police,5,3) in ('503','580')
		And Ga.Code_Categorie in ('503','504')
		And Date_Emission between @Date_1 and @Date_2) G 
On (Q.Numero_Reference=G.Numero_Reference
	And Q.Numero_Quittance=G.Numero_Quittance)
Join	(Select Ga.Numero_Reference,Q.Numero_Quittance,Ga.Numero_Immatriculation,Ga.Code_Categorie,Ga.Code_Sous_Garantie,
			(Case when Code_Mouvement in ('ANL') then Ga.Prime_Nette*-1 else Ga.Prime_Nette end) as Prime_Nette  ------ Lire toutes les immatriculations et leur prime CEDEAO
		From Quittance Q 
		Join Detail_Quittance DQ On (DQ.Numero_Quittance=Q.Numero_Quittance) 
		Join Garanties_Automobile Ga on Ga.Numero_Reference=Q.Numero_Reference
		Where Code_Sous_Garantie ='00260'
		----And SUBSTRING (Numero_Police,5,3) in ('503','580')
		And Ga.Code_Categorie in ('503','504')
		And Date_Emission between @Date_1 and @Date_2) Gc 
On (Gc.Numero_Reference=Q.Numero_Reference
	And Q.Numero_Quittance=Gc.Numero_Quittance
	And G.Numero_Immatriculation=Gc.Numero_Immatriculation)
Join Categorie C On (C.Code_Categorie= G.Code_Categorie)
Join Mouvement M On (M.Code_Mouvement=Q.Code_Mouvement)
Join Reference_Automobile R 
	On (R.Numero_Reference=Q.Numero_Reference 
	And R.Numero_immatriculation=G.Numero_Immatriculation)
Join Carte_Grise Ca On (Ca.Numero_Carte=R.Numero_Carte)
Join Energie E On (E.Code_Energie=Ca.Code_Energie)
Where G.Code_Categorie in ('503','504')
--SUBSTRING (Q.Numero_Police,5,3) in ('503','580')
And Q.Code_Mouvement  in ('AFN','ANL','INC','PRG','REN','RES','RET')
And Date_Emission between @Date_1 and @Date_2
Order by Libelle_Intermediaire,Numero_Police,Numero_Avenant,Numero_Immatriculation


---- SINISTRE TPV AJOUT PAR GODWIN 06/02/2023

If @Code_Etat_Controle='024' 

Select @Date_1,@Date_2
------

select S.Numero_Police,S.Numero_Avenant,Convert(Varchar,Date_Effet,103)as Date_Effet,Convert(Varchar,Date_Expiration,103)as Date_Expiration,
Convert(Varchar,Date_Survenance,103)as Date_Survenance,Convert(Varchar,Date_Declaration,103)as Date_Declaration,
S.Numero_Sinistre,Nom_Assure,Code_Objet as Immatriculation,' ' as Assure_Tiers, ' ' as Assureur_Tiers,
Ev.Montant_Evalue as Evaluation_Ouverture,Sinistre_Sap as SAP_actualise
From Sinistre S
Join Quittance Q On (Q.Numero_Quittance=S.Numero_Quittance)
Join (Select E.Numero_Sinistre,Montant_Evalue 
		From Evaluation_Sous_Garantie E
		Join (Select   Numero_Sinistre,Min(Indice_Evaluation)as Indice_Evaluation
				From Evaluation_Sous_Garantie
				Group by Numero_Sinistre) F On (F.Numero_Sinistre=E.Numero_Sinistre and E.Indice_Evaluation=F.Indice_Evaluation)
	)Ev 
On (Ev.Numero_Sinistre=S.Numero_Sinistre)
Where SUBSTRING (S.Numero_Police,5,3) in ('504')
And Date_Emission>'30/06/2021' 


---- SINISTRE TPM AJOUT PAR GODWIN 06/02/2023

If @Code_Etat_Controle='025' 

Select @Date_1,@Date_2
------

select S.Numero_Police,S.Numero_Avenant,Convert(Varchar,Date_Effet,103)as Date_Effet,Convert(Varchar,Date_Expiration,103)as Date_Expiration,
Convert(Varchar,Date_Survenance,103)as Date_Survenance,Convert(Varchar,Date_Declaration,103)as Date_Declaration,
S.Numero_Sinistre,Nom_Assure,Code_Objet as Immatriculation,' ' as Assure_Tiers, ' ' as Assureur_Tiers,
Ev.Montant_Evalue as Evaluation_Ouverture,Sinistre_Sap as SAP_actualise
From Sinistre S
Join Quittance Q On (Q.Numero_Quittance=S.Numero_Quittance)
Join (Select E.Numero_Sinistre,Montant_Evalue 
		From Evaluation_Sous_Garantie E
		Join (Select   Numero_Sinistre,Min(Indice_Evaluation)as Indice_Evaluation
				From Evaluation_Sous_Garantie
				Group by Numero_Sinistre) F On (F.Numero_Sinistre=E.Numero_Sinistre and E.Indice_Evaluation=F.Indice_Evaluation)
	)Ev 
On (Ev.Numero_Sinistre=S.Numero_Sinistre)
Where SUBSTRING (S.Numero_Police,5,3) in ('503','580')
And Date_Emission>'30/06/2021' 
And Date_Declaration between @Date_1 and @Date_2



