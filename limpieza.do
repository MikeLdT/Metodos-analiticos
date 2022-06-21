* limpieza de datos
clear 

global dir "E:\DATA\Impuestos\Miguel Lerdo de Tejada\metodos"
global do "$dir\Final\do files"
global data "E:\DATA\Impuestos\David Ontaneda"


clear
* y agrego la variable de fuacode_si_x desde la base de domicilios

foreach j of numlist 0/5 {
append using "$data\Raw\Compras201`j'_original.dta"
}

* Elimino los canales que no son supermercados
drop if inlist(idcanal, 102, 47, 74 ,  132, 283, 92 , 83 , 50 , 277 , 91 , 272 , 129 , 139 , 59 , 60 , 279 , 266 , 93 , 286 , 314 , 282 , 61 , 268 , 88 , 285 , 111 , 125 , 263 , 96 , 296 , 46 , 87 , 97 , 48 , 49 , 29 , 280 , 98 , 22 , 320 , 51 , 52 , 26 , 56 , 53 , 54 , 281 , 68 , 311 , 62 , 63 , 309 , 307 , 75 , 64 , 41 , 130 , 274 , 33 , 81 , 65 , 57 , 37 , 31 , 271 , 34 , 42 , 66 , 112 , 67, 28 , 143 , 302 , 113 , 55 , 131 , 69 , 43 , 315 , 44 , 35 , 133 , 276 , 77 , 265 , 72 , 9 , 10 , 284 , 71 , 128 , 15 , 287 , 73 , 267 , 78 , 297 , 278)

/* Convierto al precio de texto a número 
Hay un loop diferente para 2015 porque el precio original esta guardado en otro formato y no hay datos en la base de domicilios para el año 2015. Para 2015 imputo datos de domicilio de 2014 */

/*
if ano!=2015 {
destring preco, generate(precio) dpcomma
}

if ano==2015 {
gen precio = real(preco)
}
*/

if ano!=2015 {
destring preco, replace dpcomma
gen iddomicilio1=string(iddomicilio) 
gen ano1=string(ano)
gen iddom=iddomicilio1+"_"+ano1
}

if ano==2015 {
gen iddomicilio1=string(iddomicilio) 
gen ano2=2014
gen ano21=string(ano2)
gen iddom=iddomicilio1+"_"+ano21
}

gen precio = real(preco)

* Genero la variable semana en base a la fecha en que se registró cada compra 
gen mes1 = substr( data_compra, 6, 2)
gen dia = substr( data_compra, 9, 2)
egen fecha = concat (ano mes1 dia)
gen semana = wofd(date(fecha, "YMD"))
format semana %tw
drop mes1 dia fecha

*Elimino compras donde el precio sea cero
drop if precio==0 
drop if missing(semana)


*Genero la variable de precio por unidad equivalente
gen price=precio/vol_unitario
la var price "precio por unidad equivalente"


merge m:1 iddom using "$data\Raw\Domicilios.dta"
keep if _merge==3

egen canasta=group(data_compra iddomicilio idcanal)


cap drop high_bmi m_imcjf  m_nse
sort iddomicilio ano

****
*BMI
*******

destring imcjf, gen(num_imcjf) force
replace num_imcjf=. if num_imcjf < 14 | num_imcjf > 46
sort iddomicilio ano

by iddomicilio: egen m_imcjf=mode(num_imcjf), min

*by iddomicilio: gen flag_first_obs = _n == 1
egen flag_first_obs=tag(iddomicilio)
egen median_unweighted_bmi = median(m_imcjf) if flag_first_obs

egen median=median(m_imcjf)
gen high_bmi = m_imcjf > median
drop median


*****
*NSE 
******

sort iddomicilio ano

* AB y C+ como 20%
*C como 20%
*D+ como 30%
*D y E como 30%

************** 4 NSE ****************

by iddomicilio: egen m_nse=mode(nse_loc), min
gen nse_4=1 if inlist(m_nse,1,2) 
* el nse mas alto es 1
replace nse_4=2 if inlist(m_nse, 3)
replace nse_4=3 if inlist(m_nse, 4)
replace nse_4=4 if inlist(m_nse, 5, 6)

label define nse_4l 1 "AB y C+" 2 "C" 3 "D+" 4 "D y E" 
label values nse_4 nse_4l 

************* 2 NSE *****************

gen nse_2=1 if inlist(m_nse,1,2,3) 
* el nse mas alto es 1
replace nse_2=2 if inlist(m_nse,4,5,6)
*by iddomicilio: gen flag_first_obs = _n == 1
*egen flag_first_obs=tag(iddomicilio)
egen median_unweighted_nse = median(nse_loc) if flag_first_obs

foreach agno of numlist 2010/2015{
preserve
keep if ano==`agno'
save "$dir\base_`agno'.dta", replace
restore
}

label define nse_2l 1 "AB, C+ y C" 2 "D+, D y E" 
label values nse_2 nse_2l 

keep subproduto slpsh slac sexpsh sexac semana quantidade promocao produto price preco precio num_imcjf nse_loc nse_4 nse_2 nom_sun nom_mun nom_ent nipsh nima18 niac ni mes median_unweighted_bmi masc marca zona m_nse m_imcjf ime imcjf imc idsub idpromocao idproduto idmarca idforma_compra idfabricante iddomicilio iddom idconteudo idcanal idartigo high_bmi geometry_location_lng geometry_location_lat fuaname_x fuaname_en_x fuacode_si_x forma_compra flggranel flag_first_obs fem cve_mun cve_ent cv conteudo descrip_slpsh descrip_slac descrip_sexpsh descrip_ime descrip_sexac descrip_imc cmas fabricante descrip_nse_loc descrip_fem edpsh descrip_nipsh descrip_edpsh descrip_edac descrip_nima18 descrip_niac descrip_diabet clas05 clas04 clas03 clas02 clas01 descrip_ni descrip_cmas edac diabet descrip_masc cdc05 cdc04 cdc03 cdc02 cdc01 canasta canal descrip_zona descrip_adol descrip_acpsh data_compra ano cve_sun adol acpsh descrip_cv

save "$dir\base.dta", replace

