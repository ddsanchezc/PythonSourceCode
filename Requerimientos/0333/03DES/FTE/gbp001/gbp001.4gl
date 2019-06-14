###############################################################################
# PROGRAMA: gbp001.4gl
# VERSION : 1.0
# FECHA   : 29/09/93
# OBJETIVO: Parametros Diarios 
# AUTOR   : Mario del Rio  
# COMPILAR: gbp001.4gl gb000.4gl
# V 3.0.0 : Solicita tipo de cambio UFV
# CODIGO	REQ   USUARIO			       FECHA		    MOTIVO    
#(@#)1-A	13785	SS-PAMELA RAMIREZ	16/07/2014    	Actualizacion automatica plazas satelites de canales externos (ROYMA)
#(@#)2-A	     	JFA-JUAN FERNANDEZ	17/09/2014    HD 77848:NO SE ACTUALIZA EN PLAZA SATELITE 711 DEL CANAL EXTERNO PARAMETRIZADO 
#(@#)3-A	14774	SS-PAMELA RAMIREZ	24/10/2014    	Cambio de logica para actualizacion automatica de agencias de canales externos
#(@#)4-A	16554	SS-PAMELA RAMIREZ	06/08/2015    	Eliminacion de Solicitudes de CrediEfectivo no desembolsados
#(@#)5-A	22816	IDE - JFLORES			07/08/2018    	Ajuste por el proyecto centralizacion
#(@#)6-A	24127	DARY SANCHEZ			05/06/2019    	CAMBIO DE FECHA DE TODAS LAS AGENCIAS
###############################################################################
DATABASE tbsfi
        DEFINE  t1 RECORD
                     gbpmtfdia  LIKE gbpmt.gbpmtfdia,
                     gbpmtscam  LIKE gbpmt.gbpmtscam,
                     gbpmttcof  LIKE gbpmt.gbpmttcof,
                     gbpmttcco  LIKE gbpmt.gbpmttcco,
                     gbpmttcve  LIKE gbpmt.gbpmttcve,
                     gbpmttufv  LIKE gbpmt.gbpmttufv		# V 3.0.0
							
                   END RECORD,
                   g_fdia       LIKE gbpmt.gbpmtfdia,
                   g_tcof       LIKE gbpmt.gbpmttcof,
                   g_tcco       LIKE gbpmt.gbpmttcco,
                   g_tcve       LIKE gbpmt.gbpmttcve,
                   g_tufv       LIKE gbpmt.gbpmttufv,		# V 3.0.0
                   g_user       LIKE gbhtc.gbhtcuser,
                   g_hora       LIKE gbhtc.gbhtchora,
                   g_fpro       LIKE gbhtc.gbhtcfpro,
		g_host		CHAR(25),
#MAG
		t2     RECORD
                        dni     CHAR(8),
                        nomb    CHAR(40),
                        npre    CHAR(9),
                        cuot    SMALLINT,
                        impo    DECIMAL(14,2),
                        cmon    SMALLINT,
                        cloc    SMALLINT,
                        corr    SMALLINT
                       END RECORD,
		#(@#)6-A INICIO
		t3 RECORD
			new_fech LIKE gbpmt.gbpmtfdia   # Variable para el campo Nueva fecha
		END RECORD,

		t4 RECORD
			tbsfixxx CHAR(50),   # Variable para recorrer todas las bases de datos existentes en tbsfi
			fecha_actual_base LIKE gbpmt.gbpmtfdia, # Variable para guardar la ultima fecha registrada por agencia recorrida
			agencia_tbase LIKE gbpmt.gbpmtplaz # Variable para guardar el numero de agencia
		END RECORD,
		#(@#)6-A FIN

		g_spool		CHAR(10),
		i               SMALLINT,
                g_string        CHAR(79),
                g_ancho         SMALLINT,
		g_rpta1		CHAR(1),
		g_desc1		CHAR(46),
		g_desc2		CHAR(46),
		g_desc3		CHAR(46),
		g_desc4		CHAR(46),
		
		#(@#)6-A INICIO
		g_new_fech DATE,   # Variable global Nueva fecha
		g_ruta CHAR(200), # ruta de salida del archivo
		g_text CHAR(500),   # Variable global cadena de texto
		g_text_retail CHAR(500),   # Variable global cadena de texto retail
		g_const_guion CHAR(1),   # Variable global de caracter 'guion'
		g_const_dospuntos CHAR(1),   # Variable global de caracter 'dos puntos'
		g_const_log CHAR(20),   # Variable global de caracter extension archvo '.log'
		g_const_0 SMALLINT,   # Constante de valor 0
		g_const_1 SMALLINT,   # Constante de valor 1
		g_spool_2         CHAR(500), # Cadena de texto para nombre de archivo excel
		#(@#)6-A FIN

                #################################
                # variables generales NO BORRAR #
                #################################
                        t0         RECORD LIKE gbpmt.*,
                        version    CHAR(008),
                        g_marca    SMALLINT,
			g_rpta	   CHAR(1),
			g_ffec	   DATE		#Flag para cambio de mes
#(@#)5-A Inicio
		  ,g_fcentr SMALLINT   # Flag de centralizacion de dealers
		  ,g_gbpmttufv FLOAT 	 # Tipo de cambio UFV  
		  ,g_gbpmtcmes CHAR(1) # valor N para actualizacion de la tabla parametros 
		  ,g_val0  SMALLINT 	 # valor 0 por defecto 
		  ,g_nomp  CHAR(10) 	 # nombre del proceso	
#(@#)5-A Fin
MAIN DEFER INTERRUPT
	IF NOT f0000_open_database_gb000() THEN EXIT PROGRAM END IF
        OPTIONS ERROR  LINE 23,
                INPUT  WRAP
	SET LOCK MODE TO WAIT
	LET version = " 3.0.0 "
        IF f6050_buscar_empresa_gbp001() THEN
	    LET g_user = arg_val(1)
            LET g_fpro = TODAY
            OPEN FORM gbp001_01  FROM "gbp001a"
            DISPLAY FORM gbp001_01
            CALL f6100_cabecera_gbp001()
            CALL p0000_prepara_constantes_gbp001() #(@#)5-A
            CALL f6000_limpiar_menu_gbp001()
            LET t1.gbpmtscam = t0.gbpmtscam
            CALL f6300_display_datos_gbp001()
				#(@#)6-A INICIO
				CALL f0251_preparar_cursores_gbp001()
				#(@#)6-A FIN
            CALL f0300_proceso_gbp001()
				#(@#)6-A INICIO
				CALL f0010_libera_cursores_gbp001()
				#(@#)6-A FIN
        ELSE
	    ERROR "No existen parametros iniciales"
	    SLEEP 2
        END IF
END MAIN

#(@#)6-A INICIO
FUNCTION f0251_preparar_cursores_gbp001()
# Descripción: Funcion que inicializa cursores
	DEFINE
		l_text	CHAR(1000) # Cadena de texto para llenar informacion de agencias

	LET l_text = " SELECT gbofinofi,gbofidesc,gbofihost,gboficemp",
					" FROM tbsfi:gbofi ",
					" order by gbofinofi "
	PREPARE p_sql_2    FROM l_text
	DECLARE c_cursor_excel CURSOR FOR p_sql_2
END FUNCTION
#(@#)6-A FIN

#(@#)6-A INICIO
FUNCTION f0010_libera_cursores_gbp001()
# Descripción: Función que libera cursores
	FREE c_cursor_excel
END FUNCTION
#(@#)6-A FIN

#################
# PROCESO CENTRAL
#################
#(@#)5-A Inicio
FUNCTION p0000_prepara_constantes_gbp001() 
#DESCRIPCION: proceso para inicializar variables constantes
		LET g_gbpmtcmes = "N"
		LET g_val0 = 0
		LET g_nomp = "gbp001"
		#(@#)6-A INICIO
		LET g_const_0 = 0
		LET g_const_0 = 1
		LET g_const_guion = "-"
		LET g_const_log = "LOG_gbp001",g_const_guion
		LET g_const_dospuntos = ":"
		LET g_ruta = "/u/tbsfi/prueba/DarySanchez/SFI_programa_final_v3/"
		#(@#)6-A FIN
END FUNCTION

FUNCTION	p0000_prepara_querys_gbp001()
#DESCRIPCION :Proceso para la preparacion de querys
		DEFINE l_dsql  CHAR(5000) 							# Variable para los querys
		LET l_dsql = "UPDATE egbpmt SET egbpmtfdia = ?,egbpmtscam = ?, egbpmttcof = ?,egbpmttcco = ?,egbpmttcve = ?,egbpmtcmes = ?, egbpmttufv = ? WHERE egbpmtplaz = ?"	
		PREPARE p_egbpmt_actualizacion FROM l_dsql
END	FUNCTION
#(@#)5-A Fin

#(@#)6-A INICIO
FUNCTION f101_obtener_retail_gbp001(l_tbsfi)
# Descripción: Obtiene retail de todas las agencias
	DEFINE
		l_tbsfi CHAR(100), # Variable para almacenar cadena tbase
		l_text	CHAR(1000), # Cadena de texto para llenar informacion de agencias
		l_plaz SMALLINT, # Variable codigo plaza
		l_retail CHAR(100), # Cadena Nombre retail
		l_desc	CHAR(500), # Nombre de oficina
		l_nofi	SMALLINT, # Numero de agencia
		l_ret_codi	SMALLINT, # Numero de retail
		l_ret_nomb CHAR(100), # Nombre retail
		l_nombre_salida CHAR(30) # Nombre salida log

		LET g_text = " SELECT DISTINCT gbpmtplaz,gbpmtnemp",
							" FROM ",l_tbsfi CLIPPED,":gbpmt " 
			WHENEVER sqlerror CONTINUE
			PREPARE pu02_act_fech_3 FROM g_text
			EXECUTE pu02_act_fech_3 INTO l_plaz,l_retail
			WHENEVER sqlerror STOP
			
		LET g_text_retail = " SELECT DISTINCT egbempcodi,egbempnomb",
							" FROM ",l_tbsfi CLIPPED,":egbemp " 
			WHENEVER sqlerror CONTINUE
			PREPARE pu02_act_fech_4 FROM g_text_retail
			EXECUTE pu02_act_fech_4 INTO l_ret_codi,l_ret_nomb
			WHENEVER sqlerror STOP
		
	RETURN l_plaz,l_retail,l_ret_codi,l_ret_nomb
END FUNCTION
#(@#)6-A FIN

#(@#)6-A INICIO
FUNCTION f0xxx_update_gbp001()
# DESCRIPCION: Funcion que actualiza fecha de agencias
	DEFINE 
		l_text	CHAR(1000), # texto cadena para generacion de prepare
		l_desc	CHAR(20), # nombre oficina
		l_fecha_dia DATETIME YEAR TO DAY, # fecha del nombre del reporte
		l_hora DATETIME HOUR TO SECOND, # hora del nombre del reporte
		l_cadena_fecha CHAR(10), # fecha del nombre del reporte en texto
		l_cadena_hora CHAR(8), # hora del nombre del reporte en texto
		l_extension_excel CHAR(4), # extension del archivo excel
		l_nombre_salida_excel CHAR(500) # nombre del archvivo de salida excel

	LET l_fecha_dia = CURRENT YEAR TO DAY
	LET l_hora = CURRENT HOUR TO SECOND
	LET l_cadena_fecha = l_fecha_dia
	LET l_cadena_fecha = l_cadena_fecha[9,10],g_const_guion,l_cadena_fecha[6,7],g_const_guion,l_cadena_fecha[1,4]
	LET l_cadena_hora = l_hora
	LET l_cadena_hora = l_cadena_hora[1,2],g_const_dospuntos,l_cadena_hora[4,5],g_const_dospuntos,l_cadena_hora[7,8]
	LET l_extension_excel = ".xls"
	LET l_nombre_salida_excel = g_ruta CLIPPED,g_const_log CLIPPED,g_user,g_const_guion,l_cadena_fecha CLIPPED,g_const_guion,g_const_guion,l_cadena_hora CLIPPED,l_extension_excel CLIPPED
	
	CALL STARTLOG(l_nombre_salida_excel CLIPPED)
	LET g_text = "#### INICIANDO PROCESO ... ####\n"
	CALL ERRORLOG(g_text CLIPPED)

	LET t3.new_fech = t0.gbpmtfdia
	LET t1.gbpmtfdia = TODAY
	LET t1.gbpmtfdia = g_new_fech
	LET g_spool_2 = l_nombre_salida_excel CLIPPED
	CALL f2100_detalle_excel_gbp001()
END FUNCTION
#(@#)6-A FIN

#(@#)6-A INICIO
FUNCTION f2100_detalle_excel_gbp001()
# Descripción: Función que genera el reporte para el formato excel.
	MESSAGE "Procesando archivo: ",g_ruta CLIPPED
	START REPORT imprime_rep_detallado TO g_spool_2
		CALL f5000_formato_excel_gbp001()
	FINISH REPORT imprime_rep_detallado
END FUNCTION
#(@#)6-A FIN

#(@#)6-A INICIO
REPORT imprime_rep_detallado(l_html)
	DEFINE l_html CHAR(15000)
	OUTPUT
		PAGE		length 1
		LEFT		margin 0
		BOTTOM	margin 0
		TOP		margin 0
	FORMAT ON EVERY ROW
		PRINT COLUMN 000, l_html CLIPPED
END REPORT
#(@#)6-A FIN

#(@#)6-A INICIO
FUNCTION f5000_formato_excel_gbp001()
# Descripción: Función que da el formato xls al reporte.

	DEFINE  
		l_html	CHAR(15000), # Cadena de texto para llenado en celdas de excel
		l_tita_blue,l_tita_black,l_tita_yellow,l_tita_red,l_tita_green,l_tite,l_body	VARCHAR(255), # Estilos de formato para celdas
		l_time	DATETIME HOUR TO SECOND, # Hora actual
		l_text	CHAR(1000), # Cadena de texto para llenar informacion de agencias
		l_desc	CHAR(30), # Nombre de oficina
		l_sql1	CHAR(500), # Cadena de texto para cursor que recorrera agencias
		l_nofi	SMALLINT, # Numero de agencia
		l_tbsfi CHAR(100), # Variable para almacenar cadena tbase
		l_today DATE, # Fecha actual
		l_agencia_tbsfi SMALLINT, # Variable gbpmtplaz
		l_fecha_actual_tbsfi DATE, # Variable gbpmtfdia
		l_plaz SMALLINT, # Variable codigo plaza
		l_retail CHAR(100),  # Cadena Nombre retail
		l_ret_codi	SMALLINT, # Numero de retail
		l_ret_nomb CHAR(100), # Nombre retail
		l_cemp SMALLINT
		
		LET l_today = TODAY
		LET l_tite = "style=\"color:#000000;background-color:#FFFFFF; font:12px Arial;" # FONDO BLANCO
		LET l_tita_blue = "style=\"color:#000000;background-color:#94EFE9; font:12px Arial;" # FONDO AZUL
		LET l_tita_black = "style=\"color:#FFFFFF;background-color:#000000; font:12px Arial;" # FONDO NEGRO
		LET l_tita_yellow = "style=\"color:#000000;background-color:#F5FF38; font:12px Arial;" # FONDO AMARILLO
		LET l_tita_red = "style=\"color:#FFFFFF;background-color:#C40101; font:12px Arial;" # FONDO ROJO
		LET l_tita_green = "style=\"color:#FFFFFF;background-color:#079333; font:12px Arial;" # FONDO VERDE
		LET l_body = "style=\"font-family:Arial, Helvetica, sans-serif;font-size:12px;\""
		LET l_time = CURRENT


		LET l_html=l_html CLIPPED, "<table cellspacing=\"2px\" cellpadding=\"2xp\" border = 0.01 bordercolor=\"black\" >"

		LET l_html=l_html CLIPPED, "<tr>"
		LET l_html=l_html CLIPPED, "<td ",l_tita_blue CLIPPED,"text-align:LEFT;\"></td>"
		LET l_html=l_html CLIPPED, "<td colspan= 13 ",l_tita_blue CLIPPED,"text-align:center;\"><b>" ," ", " </b></td>"
		LET l_html=l_html CLIPPED, "<td ",l_tita_blue CLIPPED,"text-align:center;\">", "","</td>"
		LET l_html=l_html CLIPPED, "</tr>"

		LET l_html=l_html CLIPPED, "<tr>"
		LET l_html=l_html CLIPPED, "<td height=18  width = 150 ",l_tita_blue CLIPPED,"text-align:CENTER;\"><b>","MODULO EFECTIVA","</b></td>"
		LET l_html=l_html CLIPPED, "<td colspan = 13 ",l_tita_blue CLIPPED,"text-align:CENTER;\"><b>","AGENCIAS SIN CAMBIO DE FECHA","</b></td>"
		LET l_html=l_html CLIPPED, "<td height=18  width = 150 ",l_tita_blue CLIPPED,"text-align:CENTER;\"><b>", "FECHA","</b></td>"
		LET l_html=l_html CLIPPED, "</tr>"

		LET l_html=l_html CLIPPED, "<tr>"
		LET l_html=l_html CLIPPED, "<td ",l_tita_blue CLIPPED,"text-align:CENTER;\"><b>", l_time,"</b></td>"
		LET l_html=l_html CLIPPED, "<td colspan = 13 " ,l_tita_blue CLIPPED,"text-align:CENTER;\"><b>","PARAMETROS DIARIOS - SFI","</b></td>"
		LET l_html=l_html CLIPPED, "<td ",l_tita_blue CLIPPED,"text-align:CENTER;\"><b>",t0.gbpmtfdia USING "dd-mm-yyyy","</b></td>"
		LET l_html=l_html CLIPPED, "</tr>"

		LET l_html=l_html CLIPPED, "<tr>"
		LET l_html=l_html CLIPPED, "<td ",l_tita_blue CLIPPED,"text-align:LEFT;\"></td>"
		LET l_html=l_html CLIPPED, "<td colspan= 13 ",l_tita_blue CLIPPED,"text-align:center;\"><b>" ," ", " </b></td>"
		LET l_html=l_html CLIPPED, "<td ",l_tita_blue CLIPPED,"text-align:center;\">", "","</td>"
		LET l_html=l_html CLIPPED, "</tr>"

		LET l_html=l_html CLIPPED, "<table cellspacing=\"2px\" cellpadding=\"2xp\" border = 1.5 bordercolor=\"black\" >"
		
      OUTPUT TO REPORT imprime_rep_detallado(l_html)
    		LET l_html=""
    		LET l_html=l_html CLIPPED, "<tr>"
    		LET l_html=l_html CLIPPED, " <td height=30  colspan= 1 ",l_tita_black CLIPPED,"vertical-align:middle;text-align:center;\"><b>CODIGO RETAIL</b></td>"
    		LET l_html=l_html CLIPPED, " <td height=30  colspan= 4 ",l_tita_black CLIPPED,"vertical-align:middle;text-align:center;\"><b>NOMBRE RETAIL</b></td>"
    		LET l_html=l_html CLIPPED, " <td height=30  colspan= 2 ",l_tita_black CLIPPED,"vertical-align:middle;text-align:center;\"><b>AGENCIA</b></td>"
    		LET l_html=l_html CLIPPED, " <td height=30  colspan= 4 ",l_tita_black CLIPPED,"vertical-align:middle;text-align:center;\"><b>NOMBRE AGENCIA</b></td>"
    		LET l_html=l_html CLIPPED, " <td height=30  colspan= 4 ",l_tita_black CLIPPED,"vertical-align:middle;text-align:center;\"><b>DESCRIPCION</b></td>"
    		LET l_html=l_html CLIPPED, "</tr>"
      OUTPUT TO REPORT imprime_rep_detallado(l_html)    
	
	OPEN c_cursor_excel 
	FETCH c_cursor_excel INTO l_nofi,l_desc,l_tbsfi,l_cemp
		WHILE STATUS <> NOTFOUND
	
			LET g_text = " SELECT gbpmtplaz,gbpmtfdia",
							" FROM ",l_tbsfi CLIPPED,":gbpmt"
			WHENEVER sqlerror CONTINUE
			PREPARE pu02_act_fech_2 FROM g_text
			EXECUTE pu02_act_fech_2 INTO l_agencia_tbsfi, l_fecha_actual_tbsfi
			WHENEVER sqlerror STOP
			
			IF l_fecha_actual_tbsfi < l_today THEN
				
				LET l_text = " UPDATE ",l_tbsfi CLIPPED,":gbpmt ",
								" SET gbpmtfdia = '",g_new_fech,"'"
				WHENEVER sqlerror CONTINUE
				PREPARE pu01_act_fech_3 FROM l_text
				EXECUTE pu01_act_fech_3
				WHENEVER sqlerror STOP
				
				CALL f101_obtener_retail_gbp001(l_tbsfi CLIPPED)
				RETURNING l_plaz,l_retail,l_ret_codi,l_ret_nomb
				
				IF l_nofi = l_plaz THEN 
					IF SQLCA.SQLCODE < 0 THEN
						LET l_text = "NO SE ACTUALIZÓ FECHA EN AGENCIA EXTERNA "
						LET l_html="<tr>",
						" <td height=25  colspan= 1 ",l_tita_red CLIPPED,"vertical-align:middle;text-align:center;\">",l_cemp,"</td>",
						" <td height=25  colspan= 4 ",l_tita_red CLIPPED,"vertical-align:middle;text-align:center;\">",l_ret_nomb,"</td>",
						" <td height=25  colspan= 2 ",l_tita_red CLIPPED,"vertical-align:middle;text-align:center;\">",l_nofi,"</td>",
						" <td height=25  colspan= 4 ",l_tita_red CLIPPED,"vertical-align:middle;text-align:center;\">",l_retail CLIPPED,"</td>",
						" <td height=25  colspan= 4 ",l_tita_red CLIPPED,"vertical-align:middle;text-align:center;\">",l_text,"</td>",
						"</tr>"
					
					ELSE
						
						LET l_text = "SE ACTUALIZÓ FECHA EN AGENCIA EXTERNA "
						LET l_html="<tr>",
						" <td height=25  colspan= 1 ",l_tita_yellow CLIPPED,"vertical-align:middle;text-align:center;\">",l_cemp,"</td>",
						" <td height=25  colspan= 4 ",l_tita_yellow CLIPPED,"vertical-align:middle;text-align:center;\">",l_ret_nomb,"</td>",
						" <td height=25  colspan= 2 ",l_tita_yellow CLIPPED,"vertical-align:middle;text-align:center;\">",l_nofi,"</td>",
						" <td height=25  colspan= 4 ",l_tita_yellow CLIPPED,"vertical-align:middle;text-align:center;\">",l_retail CLIPPED,"</td>",
						" <td height=25  colspan= 4 ",l_tita_yellow CLIPPED,"vertical-align:middle;text-align:center;\">",l_text,"</td>",
						"</tr>"
					END IF
					OUTPUT TO REPORT imprime_rep_detallado(l_html)
				END IF
				
			ELSE
				
				CALL f101_obtener_retail_gbp001(l_tbsfi CLIPPED)
				RETURNING l_plaz,l_retail,l_ret_codi,l_ret_nomb
				
				IF l_nofi = l_plaz THEN
					LET l_text = "AGENCIA YA SE ENCUENTRA ACTUALIZADA A LA FECHA --> ",TODAY
					LET l_html="<tr>",
								" <td height=25  colspan= 1 ",l_tita_green CLIPPED,"vertical-align:middle;text-align:center;\">",l_cemp,"</td>",
								" <td height=25  colspan= 4 ",l_tita_green CLIPPED,"vertical-align:middle;text-align:center;\">",l_ret_nomb,"</td>",
								" <td height=25  colspan= 2 ",l_tita_green CLIPPED,"vertical-align:middle;text-align:center;\">",l_nofi,"</td>",
								" <td height=25  colspan= 4 ",l_tita_green CLIPPED,"vertical-align:middle;text-align:center;\">",l_retail CLIPPED,"</td>",
								" <td height=25  colspan= 4 ",l_tita_green CLIPPED,"vertical-align:middle;text-align:center;\">",l_text,"</td>",
								"</tr>"
					OUTPUT TO REPORT imprime_rep_detallado(l_html)
				END IF
			END IF
		
		FETCH c_cursor_excel INTO l_nofi,l_desc,l_tbsfi,l_cemp
		END WHILE
		CLOSE c_cursor_excel
END FUNCTION
#(@#)6-A FIN

FUNCTION f0300_proceso_gbp001()
#DESCRIPCION :Proceso central  #(@#)5-A
	DEFINE l_fecha	DATE
	
		CALL p0000_prepara_querys_gbp001() #(@#)5-A
	LET g_ffec = FALSE
	#(@#)6-A INICIO
	LET t0.gbpmtfdia = TODAY
	LET t3.new_fech = t0.gbpmtfdia
	LET t1.gbpmtfdia = TODAY
	#(@#)6-A FIN
		  INPUT   BY NAME t1.* WITHOUT DEFAULTS
		ON KEY (CONTROL-C,INTERRUPT)
		        LET int_flag = TRUE 
			EXIT INPUT
			       
					
                BEFORE FIELD gbpmttcof
                        IF t0.gbpmtplaz <> 0 THEN
                                NEXT FIELD gbpmttufv
                        END IF
                BEFORE FIELD gbpmttcco
                        IF t0.gbpmtplaz <> 0 THEN
                                NEXT FIELD gbpmttufv
                        END IF
                BEFORE FIELD gbpmttcve
                        IF t0.gbpmtplaz <> 0 THEN
                                NEXT FIELD gbpmttufv
                        END IF
					#(@#)6-A INICIO
					AFTER FIELD gbpmtfdia
					IF t1.gbpmtfdia IS NULL THEN
						NEXT FIELD gbpmtfdia
					END IF
					LET g_new_fech = t1.gbpmtfdia
					DISPLAY g_new_fech  AT 4,66 
					CALL f0xxx_update_gbp001()
					#(@#)6-A FIN
					
			IF MONTH(t0.gbpmtfdia) <> MONTH(t1.gbpmtfdia) THEN
			    #IF f9100_verifica_autoriz_gbp001() THEN
			    IF t0.gbpmtplaz <> 88 AND t0.gbpmtcmes = "N" THEN
				OPEN WINDOW wgbp001f AT 8,13 WITH FORM "gbp001f"
				    ATTRIBUTE (REVERSE, FORM LINE 1)
				OPTIONS INPUT NO WRAP
				INPUT BY NAME g_rpta WITHOUT DEFAULTS
				    ON KEY (INTERRUPT,CONTROL-C)
					EXIT INPUT
				END INPUT
				CLOSE WINDOW wgbp001f
				LET int_flag = TRUE
				EXIT INPUT
			    END IF
			    LET g_ffec = TRUE
			END IF
			LET t1.gbpmtfdia = f0310_fecha_gb000(t1.gbpmtfdia)
			DISPLAY BY NAME
								t1.gbpmtfdia
                        IF t1.gbpmtfdia < t0.gbpmtfdia THEN
                            ERROR "No puede ser menor a Fecha Anterior"
                            NEXT FIELD gbpmtfdia
                        END IF
                        IF t1.gbpmtfdia < t0.gbpmtfini OR
                           t1.gbpmtfdia > t0.gbpmtffin THEN
                            ERROR "Fecha no comprende la gestion presente"
                            NEXT FIELD gbpmtfdia
                        END IF
			IF t1.gbpmtfdia > t0.gbpmtfdia THEN
			    ##  Verificar Cierre y Posteo de M¢dulos
			    IF t0.gbpmtplaz <> 88 AND 
			       (NOT f7000_ver_cierres_gbp001()) THEN
				NEXT FIELD gbpmtfdia
			    END IF
			END IF
                        IF t1.gbpmtfdia - t0.gbpmtfdia > 3 THEN
                            ERROR "PRECAUCION: Considerable diferencia ",
                                  "en el cambio de fecha!!!"
                        END IF

			#Validando Cancelaci¢n de Devoluci¢n de Mercaderia
			{LET l_fecha = MDY(MONTH(t0.gbpmtfdia)+1,1,
						YEAR(t0.gbpmtfdia))-1
			IF (l_fecha - t0.gbpmtfdia) < 4 THEN
			    IF NOT f7000_ver_canc_devmerc_gbp001() THEN
                                OPEN WINDOW wgb001c AT  8, 15
                                    WITH FORM "gbp001c"
                                    ATTRIBUTE (REVERSE, FORM LINE 1)
                                OPTIONS INPUT NO WRAP
                                DISPLAY BY NAME g_desc1
                                DISPLAY BY NAME g_desc2
                                DISPLAY BY NAME g_desc3
                                DISPLAY BY NAME g_desc4
                                INPUT BY NAME g_rpta1 WITHOUT DEFAULTS
                                    ON KEY (INTERRUPT,CONTROL-C)
                                        LET int_flag = TRUE
                                        EXIT INPUT
                                END INPUT
                                CLOSE WINDOW wgb001c
				NEXT FIELD gbpmtfdia
			    END IF	
			END IF}
			#################################################
			##--> SOLO PUEDE CAMBIARLO LA AGENCIA DE LIMA ###
			#################################################
                  IF t0.gbpmtplaz <> 88 THEN
                                CALL leer_tipo_cambio_plaza_gb306(t0.gbpmtplaz,t1.gbpmtfdia)
                                       	RETURNING t1.gbpmttcof,t1.gbpmttcco,t1.gbpmttcve,t1.gbpmttufv
	                        DISPLAY BY NAME t1.gbpmttcof
        	                DISPLAY BY NAME t1.gbpmttcco
                	        DISPLAY BY NAME t1.gbpmttcve
				DISPLAY BY NAME t1.gbpmttufv
	                        NEXT FIELD gbpmttufv
		        ELSE
                                CALL leer_tipo_cambio_plaza_gb306(t0.gbpmtplaz,t1.gbpmtfdia)
                                        RETURNING t1.gbpmttcof,t1.gbpmttcco,t1.gbpmttcve,t1.gbpmttufv
                                DISPLAY BY NAME t1.gbpmttcof
                                DISPLAY BY NAME t1.gbpmttcco
                                DISPLAY BY NAME t1.gbpmttcve
                                DISPLAY BY NAME t1.gbpmttufv
        	        END IF
                AFTER FIELD gbpmtscam
                        IF t1.gbpmtscam IS NULL THEN
                            NEXT FIELD gbpmtscam
                        END IF
                AFTER FIELD gbpmttcof
                        IF t1.gbpmttcof IS NULL THEN
                            LET t1.gbpmttcof = t0.gbpmttcof
                            DISPLAY BY NAME t1.gbpmttcof
                        END IF
                        IF t1.gbpmttcof > t0.gbpmttcof + t1.gbpmtscam OR
                           t1.gbpmttcof < t0.gbpmttcof - t1.gbpmtscam THEN
                            ERROR "Valor no esta en el rango de la ",
                                  "Sensibilidad Cambiaria"
                            NEXT FIELD gbpmttcof
                        END IF
                AFTER FIELD gbpmttcco
                        IF t1.gbpmttcco IS NULL THEN
                            LET t1.gbpmttcco = t0.gbpmttcco
                            DISPLAY BY NAME t1.gbpmttcco
                        END IF
                        IF t1.gbpmttcco > t0.gbpmttcco + t1.gbpmtscam OR
                           t1.gbpmttcco < t0.gbpmttcco - t1.gbpmtscam THEN
                            ERROR "Valor no esta en el rango de la ",
                                  "Sensibilidad Cambiaria"
                            NEXT FIELD gbpmttcco
                        END IF
                AFTER FIELD gbpmttcve
                        IF t1.gbpmttcve IS NULL THEN
                            LET t1.gbpmttcve = t0.gbpmttcve
                            DISPLAY BY NAME t1.gbpmttcve
                        END IF
                        IF t1.gbpmttcve > t0.gbpmttcve + t1.gbpmtscam OR
                           t1.gbpmttcve < t0.gbpmttcve - t1.gbpmtscam THEN
                            ERROR "Valor no esta en el rango de la ",
                                  "Sensibilidad Cambiaria"
                            NEXT FIELD gbpmttcve
                        END IF
                AFTER FIELD gbpmttufv		# V 3.0.0
                        IF t1.gbpmttufv IS NULL THEN
                            LET t1.gbpmttufv = t0.gbpmttufv
                            DISPLAY BY NAME t1.gbpmttufv
                        END IF
                        MESSAGE " <ESC> para grabar..."
                AFTER INPUT
                        IF t1.gbpmtscam IS NULL THEN
                            NEXT FIELD gbpmtscam
                        END IF
                        IF t1.gbpmttcof IS NULL THEN
                            NEXT FIELD gbpmttcof
                        END IF
                        IF t1.gbpmttcco IS NULL THEN
                            NEXT FIELD gbpmttcco
                        END IF
                        IF t1.gbpmttcve IS NULL THEN
                            NEXT FIELD gbpmttcve
                        END IF
	END INPUT
	IF int_flag THEN
            RETURN
        END IF
	###################################################################################
        ##--SI ES AGENCIA DE LIMA GRABA A TODA LA COMPANIA EN LA TABLA gbhtc -->Historico
	###################################################################################
	{
        IF t0.gbpmtplaz = 50 THEN
             IF NOT verificar_hist_con_fecha(t1.gbpmtfdia) THEN
                 CALL actualiza_tipo_cambio_compania_gb306(t1.gbpmtfdia)
             ELSE
                 CALL Ingresa_tipo_cambio_compania_gb306()
             END IF
        END IF
	}
        CALL f2000_modificar_gbp001()

END FUNCTION

###########################
# MODIFICACION DE REGISTROS
###########################

FUNCTION f9100_verifica_autoriz_gbp001() 
	IF t0.gbpmtcmes = "N" THEN
	    RETURN TRUE
	ELSE
	    RETURN FALSE
	END IF
END FUNCTION

FUNCTION f2000_modificar_gbp001()
#DESCRIPCION: Actualizacion de tabla de parametros #(@#)5-A 	
	DEFINE	l1	RECORD LIKE adusr.*, 
		l_dia   SMALLINT,
		l_clav	CHAR(30),
		l2      RECORD LIKE pvctl.*,
		l_mpmt  SMALLINT,
		l_mctl  SMALLINT
#(@#)1-A Inicio
		,l_cont	SMALLINT
		,l_agen SMALLINT
#(@#)1-A Fin
#(@#)3-A Inicio
		,l_desc CHAR(100)
#(@#)3-A Fin		
	##
LET g_fcentr = f5000_buscar_flag_activo_centralizacion_gb000() #(@#)5-A 	
        WHENEVER ERROR CONTINUE
        BEGIN WORK
        UPDATE gbpmt
           SET gbpmtfdia = t1.gbpmtfdia,
               gbpmtscam = t1.gbpmtscam,
               gbpmttcof = t1.gbpmttcof,
               gbpmttcco = t1.gbpmttcco,
               gbpmttcve = t1.gbpmttcve,
               gbpmttufv = t1.gbpmttufv		# V 3.0.0
        IF status < 0 THEN
	    ERROR "ERROR: Actualizando gbpmt"
            ROLLBACK WORK
            RETURN
        END IF
        LET g_hora = TIME


#	SELECT * FROM gbhtc
#	WHERE gbhtcfech = t1.gbpmtfdia
#
#	IF status = NOTFOUND THEN
#	    INSERT INTO gbhtc		# V 3.0.0
#		       VALUES (t1.gbpmtfdia,t1.gbpmttcof,t1.gbpmttcco,
#                               t1.gbpmttcve,t1.gbpmttufv,g_user      ,
#			       g_hora      ,g_fpro      )
#            IF status < 0 THEN
#	        ERROR "ERROR: Insertando gbhtc"
#                ROLLBACK WORK
#                RETURN
#            END IF
#            UPDATE gbpmt
#                   SET gbpmtcmes = "N"
#	ELSE
#	    UPDATE gbhtc
#	       SET gbhtcfech = t1.gbpmtfdia,
#                   gbhtctcof = t1.gbpmttcof,
#                   gbhtctcco = t1.gbpmttcco,
#                   gbhtctcve = t1.gbpmttcve,
#                   gbhtctufv = t1.gbpmttufv,		# V 3.0.0
#                   gbhtcuser = g_user,
#        	   gbhtchora = g_hora,
#        	   gbhtcfpro = g_fpro 
#             WHERE gbhtcfech = t1.gbpmtfdia
#             IF status < 0 THEN
#		 ERROR "ERROR: Actualizando gbhtc"
#                 ROLLBACK WORK
#                 RETURN
#             END IF
#	END IF
	##Verificando incorporacion del archivo de alineamiento
#	LET l_dia = DAY(t1.gbpmtfdia)


        {DESACTIVADO CON LA CENTRALIZACION
	IF l_dia >= 10 THEN  ##Si es mayor a 1 dia, el usuario del JCC se bloque
           SELECT * INTO l2.* 
               FROM pvctl 

	   LET l_mctl = MONTH(l2.pvctlfali)
	   LET l_mpmt = MONTH(t1.gbpmtfdia)

	   IF (l_mpmt - l_mctl) > 1 THEN
	      UPDATE adusr
		  SET adusrmrcb = 1
	      WHERE adusrusrn IN (SELECT adprfusrn
				     FROM adprf
				  WHERE adprfperf = "JCC")
	   END IF
	END IF	
	##}
	## Autorizaci¢n de Cambio Fecha en Cambio de Mes
	    UPDATE gbpmt 
			SET gbpmtcmes = "N"
             IF status < 0 THEN
		 ERROR "ERROR: Actualizando gbpmt"
                 ROLLBACK WORK
                 RETURN
             END IF

	     IF t0.gbpmtplaz <> 88 THEN
	        DELETE FROM efmop
	        INSERT INTO efmop VALUES(1," ")
	        INSERT INTO efmop VALUES(3," ")
	        INSERT INTO efmop VALUES(60," ")
	        INSERT INTO efmop VALUES(88," ")
	        INSERT INTO efmop VALUES(89," ")
	        INSERT INTO efmop VALUES(94," ")
	        INSERT INTO efmop VALUES(95," ")
	        INSERT INTO efmop VALUES(96," ")
	        INSERT INTO efmop VALUES(97," ")
	        INSERT INTO efmop VALUES(98," ")
	     END IF
#(@#)1-A Inicio
		LET l_cont = 0
#(@#)3-A Inicio		
		{#Identificamos si la plaza de ejecucion esta configurada como plaza principal}
		#Identificamos si la plaza de ejecucion está configurada como plaza modelo
#(@#)3-A Fin
		SELECT count(*) INTO l_cont
		FROM efpar
#(@#)3-A Inicio
		#WHERE efparpfij = 150
		WHERE efparpfij = 471
#(@#)3-A Fin
		AND efparstat = 1
#(@#)3-A Inicio		
		#AND efparent1=t0.gbpmtplaz
		AND efparplaz=t0.gbpmtplaz
#(@#)3-A Fin		
		IF l_cont>0 THEN 
			#El proceso se realizara para todas las plazas satelites de los canales externos PARAMETRIZADOS
#(@#)3-A Inicio		
			{DECLARE q_sate CURSOR FOR 
				SELECT DISTINCT efparplaz FROM efpar
                		WHERE efparpfij = 27 AND efparstat = 1
				AND efparent1=t0.gbpmtplaz 
				AND efparplaz IN (SELECT DISTINCT gbofinofi FROM gbofi,efpar
                		        	WHERE efparpfij=319 AND gboficemp=efparcor1 AND efparstat=0)
			FOREACH q_sate INTO l_agen
                		}
			DECLARE q_exter CURSOR FOR 
                		select gbofinofi,gbofidesc from gbofi where gboficemp in (select epcrelcemp from epcrel where epcreltipo=2)
			FOREACH q_exter INTO l_agen,l_desc
#(@#)3-A Fin
				IF NOT f2100_modificar_satelite_externo_gbp001(l_agen) THEN
#(@#)3-A Inicio				
					#ERROR "No se actualizo en plaza satelite ",l_agen USING "<<<<<"," del canal externo parametrizado"
					ERROR "No se actualizo en agencia externa ",l_agen USING "<<<<<"," ",l_desc CLIPPED
#(@#)3-A Fin
					ROLLBACK WORK
					RETURN
				END IF
			END FOREACH		
		END IF
#(@#)1-A Fin
		     
        COMMIT WORK
	CALL f0310_enviar_lista_cbza_itin_edpyme_ef122()
{
	### 21 = Bco.Economico; 40 = Mutual La Paz; 4 = Coop.La Merced ###
	###  6 = Mutual La Plata; 55 = Coop. Fatima, 60 = Coop. San Martin ###
	### 18 = Coop. San Luis; 44 = Coop. San Gabriel y Buen Samaritano ###
	IF t0.gbpmtcbco = 21 OR t0.gbpmtcbco = 40 OR t0.gbpmtcbco = 60 OR
	   t0.gbpmtcbco = 4  OR t0.gbpmtcbco = 6  OR t0.gbpmtcbco = 55 OR
	   t0.gbpmtcbco = 18 OR t0.gbpmtcbco = 44 THEN
		#
		# ACTIVA PROCESO DE DESPIGNORACION DE TRANSACCIONES DE TDEBITO
		#
		RUN "fglgo /u/bexe/td313.4gi &"
		EXIT PROGRAM
	END IF
}
	DECLARE c_adusr CURSOR FOR
		SELECT * FROM adusr
		 WHERE adusrclva = "S"
	FOREACH c_adusr INTO l1.*
		INITIALIZE l_clav TO NULL
		SELECT adclvclav INTO l_clav
			FROM adclv
			WHERE adclvusrn = l1.adusrusrn
			  AND adclvfech = t1.gbpmtfdia
		UPDATE adusr
			SET adusrclav = l_clav,
			    adusrfcla = t1.gbpmtfdia + 1
			WHERE adusrusrn = l1.adusrusrn
	END FOREACH
	
	#(@#)4-A Inicio
	IF NOT f2300_baja_solicitudes_crediefectivo_gbp001() THEN 
		ERROR "ERROR EN ACTUALIZACION DE SOLICITUDES DE CREDIEFECTIVO" SLEEP 2
	END IF 
	#(@#)4-A Fin
END FUNCTION

#(@#)1-A Inicio
FUNCTION f2100_modificar_satelite_externo_gbp001(l_agen)
DEFINE 	l_agen SMALLINT,
	l_text	CHAR(1500),
	l_host	CHAR(50)
	,l_sqlc INTEGER #codigo que almacena la variable sql #(@#)5-A
	LET l_host = f0020_buscar_bd_gb000(l_agen,'F')
	
	IF STATUS=NOTFOUND THEN 
		RETURN FALSE
	END IF
	LET l_text = "UPDATE ",l_host CLIPPED,":gbpmt",
           		" SET gbpmtfdia = '",t1.gbpmtfdia,"',",
               		" gbpmtscam = ",t1.gbpmtscam,",",
               		" gbpmttcof = ",t1.gbpmttcof,",",
               		" gbpmttcco = ",t1.gbpmttcco,",",
               		" gbpmttcve = ",t1.gbpmttcve,",",
               		" gbpmtcmes = 'N',",
               		# " gbpmttufv = ",t1.gbpmttufv    #(@#)2-A
               		" gbpmttufv = ",f1012_Obtener_Valor_Cadena_gb000(0,t1.gbpmttufv)			#(@#)2-A
        PREPARE q_sat1 FROM l_text
        EXECUTE q_sat1
        IF status < 0 THEN
            RETURN FALSE
        END IF
#(@#)5-A inicio
		IF g_fcentr THEN
	  		IF f5000_buscar_dealer_centralizado_gb000(l_agen) THEN
	  				EXECUTE p_egbpmt_actualizacion USING t1.gbpmtfdia,t1.gbpmtscam,t1.gbpmttcof,t1.gbpmttcco,t1.gbpmttcve,g_gbpmtcmes,g_gbpmttufv,l_agen
						LET l_sqlc =  SQLCA.SQLCODE	 IF l_sqlc < g_val0 THEN	DISPLAY "ERROR EN BASE DE DATOS",l_sqlc  RETURN END IF
	  		END IF
	 END IF
#(@#)5-A Fin
	 IF l_agen <> 88 THEN
	    	LET l_text = "DELETE FROM ",l_host CLIPPED,":efmop"
        	PREPARE q_sat2 FROM l_text
        	EXECUTE q_sat2
	    	LET l_text = "INSERT INTO ",l_host CLIPPED,":efmop VALUES(3,' ')"
        	PREPARE q_sat3 FROM l_text
        	EXECUTE q_sat3	        		    
	    	LET l_text = "INSERT INTO ",l_host CLIPPED,":efmop VALUES(60,' ')"
        	PREPARE q_sat4 FROM l_text
        	EXECUTE q_sat4	        		    
	    	LET l_text = "INSERT INTO ",l_host CLIPPED,":efmop VALUES(88,' ')"
        	PREPARE q_sat5 FROM l_text
        	EXECUTE q_sat5	        		    
	    	LET l_text = "INSERT INTO ",l_host CLIPPED,":efmop VALUES(89,' ')"
        	PREPARE q_sat6 FROM l_text
        	EXECUTE q_sat6	        		    
	    	LET l_text = "INSERT INTO ",l_host CLIPPED,":efmop VALUES(94,' ')"
        	PREPARE q_sat7 FROM l_text
        	EXECUTE q_sat7	        		    
	    	LET l_text = "INSERT INTO ",l_host CLIPPED,":efmop VALUES(95,' ')"
        	PREPARE q_sat8 FROM l_text
        	EXECUTE q_sat8	        		    
	    	LET l_text = "INSERT INTO ",l_host CLIPPED,":efmop VALUES(96,' ')"
        	PREPARE q_sat9 FROM l_text
        	EXECUTE q_sat9	        		    
	    	LET l_text = "INSERT INTO ",l_host CLIPPED,":efmop VALUES(97,' ')"
        	PREPARE q_sat10 FROM l_text
        	EXECUTE q_sat10
	    	LET l_text = "INSERT INTO ",l_host CLIPPED,":efmop VALUES(98,' ')"
        	PREPARE q_sat11 FROM l_text
        	EXECUTE q_sat11
	 END IF
        RETURN TRUE
END FUNCTION
#(@#)1-A Fin

#########################
## RUTINAS DE SANTIAGO ##
#########################

FUNCTION verificar_hist_con_fecha(l_fecha)
        DEFINE  l_fecha         DATE,
                l_cont          SMALLINT

        SELECT COUNT(*) INTO l_cont
                FROM gbhtc
                WHERE gbhtcfech = l_fecha

        IF l_cont > 0 THEN
             RETURN FALSE
        ELSE
             RETURN TRUE
        END IF
END FUNCTION

FUNCTION actualiza_tipo_cambio_compania_gb306(l_fecha)
        DEFINE l_text           CHAR(500),
               l_host           CHAR(25),
               l_plaz           SMALLINT,
               l_fecha          DATE

	LET g_hora =TIME

        DECLARE q_ofi1 CURSOR FOR
        SELECT DISTINCT gbofinofi
                FROM tbsfi:gbofi
	
        #ET l_fecha = TODAY
        FOREACH q_ofi1 INTO l_plaz
                LET l_host = f0020_buscar_bd_gb000(l_plaz,"F")

                LET l_text = "UPDATE ", l_host CLIPPED, ":gbhtc ",
                             " SET gbhtctcof = ",t1.gbpmttcof,",",
                             " gbhtctcco = ",t1.gbpmttcco,",",
                             " gbhtctcve = ",t1.gbpmttcve,",",
			     " gbhtctufv = ",t1.gbpmttufv,",",
			     " gbhtcuser = '",g_user,"' ,",
			     " gbhtchora = '",g_hora,"' ,",
			     " gbhtcfpro = '",g_fpro,"' ",
                             " WHERE gbhtcfech = '",l_fecha,"'"
                PREPARE c_cpctl2 FROM l_text
                EXECUTE c_cpctl2
                IF status < 0 THEN
                        ERROR "No pude Actualizar en el Historico el TCL "
                        RETURN FALSE
                END IF

        END FOREACH
MESSAGE "TERMINA LA ACTUALIZACION"
SLEEP 2
END FUNCTION

FUNCTION Ingresa_tipo_cambio_compania_gb306()
        DEFINE l_text           CHAR(500),
               l_host           CHAR(25),
               l_plaz           SMALLINT,
               l_fecha          DATE

        DECLARE q_ofi CURSOR FOR
        SELECT DISTINCT gbofinofi
                FROM tbsfi:gbofi

        LET l_fecha = TODAY
	LET g_hora = TIME

        FOREACH q_ofi INTO l_plaz

                LET l_host = f0020_buscar_bd_gb000(l_plaz,"F")
                LET l_text = "INSERT INTO ",l_host CLIPPED,":gbhtc ",
                             "VALUES (?,?,?,?,?,?,?,?) "
                PREPARE g_gbhtc FROM l_text
                EXECUTE g_gbhtc USING t1.gbpmtfdia,t1.gbpmttcof,t1.gbpmttcco,
                                      t1.gbpmttcve,t1.gbpmttufv,g_user,g_hora,g_fpro

                IF status < 0 THEN
                   ERROR "No pude grabar en el Historico el TCL "
                   RETURN FALSE
                END IF

        END FOREACH

END FUNCTION

FUNCTION leer_tipo_cambio_plaza_gb306(l_plaz,l_fech )
        DEFINE l_plaz   SMALLINT,
               l_text   CHAR(500),
               l_host   CHAR(25),
               l_fech   DATE,
               l_tcof   DECIMAL(6,3),
               l_tcco   DECIMAL(6,3),
               l_tcve   DECIMAL(6,3),
	       l_tufv   DECIMAL(6,3)	

        LET l_host = f0020_buscar_bd_gb000(l_plaz,"F")
        LET l_text = "SELECT FIRST 1 gbhtctcof,gbhtctcco,gbhtctcve,gbhtctufv ",
                     "FROM ",l_host CLIPPED,":gbhtc ",
                     " WHERE gbhtcfech = '",l_fech,"'"
        PREPARE l_gbhtc FROM l_text
        DECLARE q_curs3 CURSOR FOR l_gbhtc

        FOREACH q_curs3 INTO l_tcof,l_tcco,l_tcve,l_tufv END FOREACH

        RETURN l_tcof,l_tcco,l_tcve,l_tufv

END FUNCTION


#############################################3
# RUTINAS DE ENVIO DE COBRANZAS ITINERANTES
# MAG
#############################################
FUNCTION f0250_declara_itinerantes_ef122()
        DECLARE q_cursor CURSOR FOR
                SELECT  cjtitdni as dni,
                        cjtrnnomb as nomb,
                        cjtitnpre as ncre,
                        cjtitcuot as cuot,
                        cjtrnimpo as imp,
                        cjtrncmon as cmon,
                        cjtitcloc as cloc,
                        cjtrncorr as corr
                FROM cjtit,cjtrn
                WHERE   cjtitntra = cjtrnntra AND
                        cjtrnftra =  t0.gbpmtfdia
                        AND cjtrnstat <> 9
                        ORDER BY cjtitcloc,cjtrnnomb
END FUNCTION
FUNCTION f7000_crear_temporal_ef122()
        CREATE TEMP TABLE tmp_cjitl #listado de locales destino del cobro
                (
                tmp_cjitlcloc   SMALLINT,
                tmp_cjitldesc   CHAR(20)
                )
        LOAD FROM "/u/bexe/LSUCURSALES.TXT"
                INSERT INTO tmp_cjitl
END FUNCTION
FUNCTION f1010_establece_gspool_ef122()
        DEFINE          desc    CHAR(4),
                        cloc    SMALLINT
        SELECT MIN(gbpmtplaz) INTO cloc FROM gbpmt
        LET g_spool = cloc USING "&&&","edp.txt"
END FUNCTION
FUNCTION f0310_enviar_lista_cbza_itin_edpyme_ef122()
        DEFINE  comando_shell   CHAR(50)

        CALL f7000_crear_temporal_ef122()
        CALL f0250_declara_itinerantes_ef122()
        CALL f1010_establece_gspool_ef122()
        IF f1000_impreso_ef122()= 1 THEN
            LET comando_shell = "mv ", g_spool, " /u/trabajo/."
            RUN comando_shell
            LET comando_shell = "itinsfi " , g_spool CLIPPED
            RUN comando_shell
	    LET comando_shell = "rm ", " /u/trabajo/", g_spool
            RUN comando_shell
	END IF
        DROP TABLE tmp_cjitl
END FUNCTION

FUNCTION f1000_impreso_ef122()
	DEFINE sw_proceso	SMALLINT
	LET sw_proceso = -1 
        START REPORT f1100_proceso_impr_ef122 TO g_spool
        FOREACH q_cursor INTO t2.*
                OUTPUT TO REPORT f1100_proceso_impr_ef122(t2.*)
		LET sw_proceso = 1
        END FOREACH
        FINISH REPORT f1100_proceso_impr_ef122
	RETURN sw_proceso
END FUNCTION

REPORT f1100_proceso_impr_ef122(r)
        DEFINE  r       RECORD
                        dni     CHAR(8),
                        nomb    CHAR(40),
                        npre    CHAR(9),
                        cuot    SMALLINT,
                        impo    DECIMAL(14,2),
                        cmon    SMALLINT,
                        cloc    SMALLINT,
                        corr    SMALLINT
                        END RECORD
        OUTPUT
                LEFT MARGIN 0
                TOP  MARGIN 0
                BOTTOM MARGIN 4
                PAGE LENGTH 132
                ORDER EXTERNAL BY r.cloc,r.nomb
        FORMAT
                PAGE HEADER
                LET g_ancho  = 132
                LET g_string = t0.gbpmtnemp CLIPPED
                PRINT ASCII 15
                PRINT COLUMN  1,"MODULO EFE",
                      COLUMN ((g_ancho-length(g_string))/2),g_string CLIPPED,
                      COLUMN (g_ancho-9),"PAG: ",PAGENO USING "<<<<"
                LET g_string = "RELACION DE COBRANZAS ITINERANTES" CLIPPED
                PRINT COLUMN  1,TIME CLIPPED,
                      COLUMN ((g_ancho-length(g_string))/2),g_string CLIPPED,
                      COLUMN (g_ancho-9),TODAY USING "dd-mm-yyyy"
                LET g_string ="Al ", t0.gbpmtfdia CLIPPED
   
             PRINT COLUMN  1,"ef122.4gl",
                      COLUMN  ((g_ancho-length(g_string))/2),g_string CLIPPED
                SKIP 1 LINE

        BEFORE GROUP OF r.cloc
                FOR i=16 TO 115 PRINT COLUMN i, "="; END FOR PRINT "="
                PRINT COLUMN 16, "Cobranza de Credito correspondiente a: ",
                                f5000_buscar_sucursal_ef122(r.cloc)
                PRINT COLUMN 16, "DNI",
                      COLUMN 27,"CLIENTE",
                      COLUMN 63,"No PREST.",
                      COLUMN 76,"No CUOTA" ,
                      COLUMN 89,"IMPORTE",
                      COLUMN 109,"MDA.PRE."
                FOR i=16 TO 115 PRINT COLUMN i,"="; END FOR PRINT "="
        ON EVERY ROW
                PRINT COLUMN 16,r.dni CLIPPED,
                      COLUMN 27,r.nomb[1,35] CLIPPED,
                      COLUMN 63,r.npre CLIPPED,
                      COLUMN 82,r.cuot USING "##";
                IF r.cmon = 1 THEN
                        PRINT COLUMN 89,"S/.";
                ELSE
                        PRINT COLUMN 89,"US$";
                END IF
                PRINT
                      COLUMN 93,r.impo USING "#,###,###.##";
                IF r.corr = 3 THEN
                        PRINT COLUMN 111,"S/."
                ELSE
                        PRINT COLUMN 111,"US$"
                END IF

        PAGE TRAILER
                PRINT ASCII 18
        AFTER  GROUP OF r.cloc
                SKIP 1 LINE
END REPORT
FUNCTION f5000_buscar_sucursal_ef122(cloc)
        DEFINE  cloc    SMALLINT,
                desc    CHAR(20)
        SELECT tmp_cjitldesc INTO desc
        FROM tmp_cjitl
        WHERE tmp_cjitlcloc = cloc
        IF status = NOTFOUND THEN
            LET desc = " "
        END IF
        RETURN desc
END FUNCTION
###################
# RUTINAS GENERALES
###################

FUNCTION f6000_limpiar_menu_gbp001()
#DESCRIPCION: proceso de limpiar variables #(@#)5-A
	CLEAR FORM		# V 3.0.0
        INITIALIZE t1.*,g_fdia,g_tcof,g_tcco,g_tcve,g_tufv TO NULL
        LET int_flag = FALSE
        LET g_marca  = FALSE
        CALL f8994_funcionalidad_set_explain_gb000(g_nomp,g_user) #(@#)5-A
END FUNCTION

FUNCTION f6050_buscar_empresa_gbp001()
        SELECT * INTO t0.* FROM gbpmt
        IF status = NOTFOUND THEN
            RETURN FALSE
        END IF
	LET g_host = f0010_buscar_database_gb000("S")
	RETURN TRUE        
END FUNCTION

FUNCTION f6100_cabecera_gbp001()
        DEFINE  l_string CHAR(33),
                l_empres CHAR(33),
                l_sistem CHAR(16),
                l_date   DATE,
                l_col    SMALLINT

# DISPLAY DEL SISTEMA
        LET     l_string = "GENERAL"
        LET     l_col = ((16 - length(l_string)) / 2)
        LET     l_sistem = " "
        LET     l_sistem[l_col+1,16-l_col] = l_string
        DISPLAY l_sistem AT 4,2

# DISPLAY DEL NOMBRE DE LA EMPRESA
        LET     l_string = t0.gbpmtnemp
        LET     l_col = ((33 - length(l_string)) / 2)
        LET     l_empres = " "
        LET     l_empres[l_col+1,33-l_col] = l_string
        DISPLAY l_empres AT 4,24

# DISPLAY DE LA FECHA
		  DISPLAY t0.gbpmtfdia USING "dd/mm/yyyy" AT 4,66 
		  
# DISPLAY DE LA OPCION
        LET     l_string = "PARAMETROS DIARIOS"
        LET     l_col = ((33 - length(l_string)) / 2)
        LET     l_empres = " "
        LET     l_empres[l_col+1,33-l_col] = l_string
        DISPLAY l_empres AT 5,24 ATTRIBUTE(REVERSE)
        DISPLAY version AT 22,70
END FUNCTION

FUNCTION f6300_display_datos_gbp001()
        LET g_fdia = t0.gbpmtfdia
        LET g_tcof = t0.gbpmttcof
        LET g_tcco = t0.gbpmttcco
        LET g_tcve = t0.gbpmttcve
        LET g_tufv = t0.gbpmttufv		# V 3.0.0
        DISPLAY BY NAME g_fdia,g_tcof,g_tcco,g_tcve,g_tufv	# V 3.0.0
END FUNCTION

###############
# OTRAS RUTINAS
###############

FUNCTION f7000_ver_cierres_gbp001()
	DEFINE	l_fech	DATE,
		l_cont	INTEGER
	#-------------- Caja ----------------#
{
	SELECT cjctlfcie INTO l_fech
		FROM cjctl
	IF l_fech IS NULL OR l_fech < t0.gbpmtfdia THEN
		ERROR "No se encontro Cierre de Caja"
		SLEEP 2
		RETURN FALSE
	END IF
	LET l_cont = 0
	SELECT COUNT(*) INTO l_cont
		FROM cjtcn
		WHERE cjtcnftra <= t0.gbpmtfdia
		  AND cjtcnpost = 0
	IF l_cont > 0 THEN
		ERROR "Existen Transacciones sin Postear en Mod. Caja"
		SLEEP 2
		RETURN FALSE
	END IF
	#------------ Prestamos -------------#
	SELECT pcctlfcie INTO l_fech
		FROM pcctl
	IF l_fech IS NULL OR l_fech < t0.gbpmtfdia THEN
		ERROR "No se encontro Cierre de Prestamos"
		SLEEP 2
		RETURN FALSE
	END IF
	LET l_cont = 0
	SELECT COUNT(*) INTO l_cont
		FROM pctcn
		WHERE pctcnftra <= t0.gbpmtfdia
		  AND pctcnpost = 0
	IF l_cont > 0 THEN
		ERROR "Existen Transacciones sin Postear en Mod. Prestamos"
		SLEEP 2
		RETURN FALSE
	END IF
	
	#------------- C.M.E. ---------------#
	SELECT lcctlfcie INTO l_fech
		FROM lcctl
	IF l_fech IS NULL OR l_fech < t0.gbpmtfdia THEN
		ERROR "No se encontro Cierre de C.M.E."
		SLEEP 2
		RETURN FALSE
	END IF
	LET l_cont = 0
	SELECT COUNT(*) INTO l_cont
		FROM lctcn
		WHERE lctcnftra <= t0.gbpmtfdia
		  AND lctcnpost = 0
	IF l_cont > 0 THEN
		ERROR "Existen Transacciones sin Postear en Mod. C.M.E."
		SLEEP 2
		RETURN FALSE
	END IF
	#MAG
	#------------Cierre de crctl para los indicadores de atrazo -----#
        SELECT crctlfcie INTO l_fech
                FROM crctl
        IF l_fech IS NULL OR l_fech < t0.gbpmtfdia THEN
                ERROR "No se encontro Cierre de Control de Atrazo del deudor"
                SLEEP 2
                RETURN FALSE
        END IF
}
	RETURN TRUE
END FUNCTION

FUNCTION f7000_ver_canc_devmerc_gbp001() 
	DEFINE	l_npre	INTEGER,
		l_fecha	DATE,
		l_cont	SMALLINT,
		l_text	CHAR(300)
	##
	LET l_fecha = MDY(MONTH(t0.gbpmtfdia),20,YEAR(t0.gbpmtfdia))
	SELECT COUNT(*) INTO l_cont
		FROM  efhti
		WHERE efhtiftra <= l_fecha
		AND   efhtitdoc = 4
		AND   efhtiestd = 2
		AND   efhtimrcb <> 9
	IF l_cont > 0 THEN
		LET g_desc1 = "Existen Prestamos en Devouci¢n de Mercaderia"
		LET g_desc2 = "Por Cancelar en Opci¢n Cobro de Prestamo"
		LET g_desc3 = "Utilizar Reporte Daci¢n de Pago TipoDoc = 4"
		LET g_desc4 = "y Estado = 2"
		RETURN FALSE
	END IF
	LET l_cont = 0
	LET l_text = "SELECT COUNT(*) FROM efhti",
		     " WHERE efhtiftra <= ? AND efhtitdoc = 4",
		     " AND efhtiestd = 3 AND efhtinpre NOT IN",
		     " (SELECT vtnvhndoc FROM ", g_host CLIPPED,
		     ":vtnvh WHERE vtnvhndoc IS NOT NULL",
		     " AND vtnvhntra IN (SELECT vtdevnvta FROM ",
		     g_host CLIPPED, ":vtdev))"
	PREPARE s_efhti FROM l_text
	DECLARE c_efhti CURSOR FOR s_efhti
	OPEN    c_efhti USING l_fecha
	FETCH   c_efhti INTO l_cont
	CLOSE   c_efhti
	FREE    c_efhti
	IF l_cont IS NULL THEN LET l_cont = 0 END IF
	IF l_cont > 0 THEN
		LET g_desc1 = "Existen Prestamos en Devouci¢n de Mercaderia"
		LET g_desc2 = "del SFI A los cuales no se les ha hecho "
		LET g_desc3 = "Nota de Credito en el SAI"
		LET g_desc4 = "Favor de Revisar"
		RETURN FALSE
	END IF
	RETURN TRUE
END FUNCTION

#(@#)4-A Inicio
FUNCTION f2300_baja_solicitudes_crediefectivo_gbp001()
	UPDATE epcprv set epcprvmrcb=9 where epcprvnpre is null and epcprvagen=t0.gbpmtplaz
	IF NOT f0500_error_gb000(STATUS,"EGBCUD") THEN
		RETURN FALSE
	END IF
	RETURN TRUE
END FUNCTION
#(@#)4-A Fin
