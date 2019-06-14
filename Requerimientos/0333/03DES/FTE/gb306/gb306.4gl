###############################################################################################################################################################
# PROGRAMA: gb306.4gl
# VERSION : 2.0.1
# OBJETIVO: Parametros Diarios 
# FECHA   : 12/09/91,29/10/96
# AUTOR   : JNC,MDR
# MODIF.  : GBT / "12/09/2005" - Verificar Posteos Diarios y Mensuales
# COMPILAR: gb306.4gl gb000.4gl ef341.4gl
# CODIGO	REQ		USR		NOMBRES			FECHA		MOTIVO
# (@#)1-A	8544		JAZ		JULIANA ALVA		09/06/2010	SE DESCOMENTO EL CODIGO DE VALIDACION DEL POSTEO DE Ctas x Pagar
# (@#)2-A	8707		JAZ		JULIANA ALVA		17/06/2010	SE VALIDO PARA QUE NO GUARE TIPO DE CAMBIO SI LOS CAMPOS SON CEROS
# (@#)3-A	3199		CEMO		Cesar E. Muguerza Ortiz	17/06/2010	Se valido el aplicativo para que no permita realizar doble cambio de fecha en los sistemas.
# (@#)4-A	3880		WPF WILMER PEREZ	 		09/06/2011     PROYECTO INDEPENDENCIA FUNCIONAL SAI - SFI
#											1. Acceso al SFI a travez de stores procedures
#											2. Cambio de base tbsfi a tabla gbofi
#											3. Reutilización de código
# (@#)5-A	####		CEMO		Cesar E. Muguerza Ortiz	29/05/2013	Se aumento el tamanho del array
# (@#)6-A	9145		LLEG		Leonardo Espinoza Gutierrez	01/10/2013	Quitar validación tarjeta virtual
# (@#)7-A	9413   		ECHM		Eder Choroco Mena			15/10/2013	Tipo de cambio en feriado
# (@#)8-A	13461   	JFA		JUAN FERNANDEZ 			03/06/2014	HD 68783:DESCARGA DE MERCADERIA DE OTRA AGENCIA ESTA PERMITIENDO REALIZAR DESCARGA DIAS DESPUES DE SU FACTURACION 
# (@#)9-A	15186   	EBC		ERWING BARTUREN 		29/12/2014	Validacion para evitar cambio de fecha a un periodo distinto al actual
# (@#)10-A	17020   	WLV		WALTER LINARES VASQUEZ	 	02/09/2015	Validacion por agencia de verificacion de anulacion de ventas sin descargar
# (@#)11-A    19211     ELIAS FLORES    				18/08/2016     ADECUACION PARA PROYECTO HYBRIS
# (@#)12-A    24127     DARY SANCHEZ    				05/06/2019     CAMBIO DE FECHA DE TODAS LAS AGENCIAS
################################################################################################################################################################

DATABASE tbase
        DEFINE  t1    RECORD
                        gbpmtfdia  LIKE gbpmt.gbpmtfdia,
                        gbpmttcof  LIKE gbpmt.gbpmttcof,
                        gbpmttcco  LIKE gbpmt.gbpmttcco,
                        gbpmttcve  LIKE gbpmt.gbpmttcve
                      END RECORD,
		t2    RECORD LIKE efchl.*,
                t3              ARRAY[20] OF RECORD
                                  avis  CHAR(40),
                                  usrr  CHAR(15),
                                  usrd  CHAR(15) 
                                END RECORD,
                                
      #(@#)12-A INICIO
		t6 RECORD
			new_fech LIKE gbpmt.gbpmtfdia   # Variable para el campo Nueva fecha
		END RECORD,

		t7 RECORD
		tbasexxx CHAR(100),   # Variable para recorrer todas las bases de datos existentes en tbase
		fecha_actual_base LIKE gbpmt.gbpmtfdia, # Variable para guardar la ultima fecha registrada por agencia recorrida
		agencia_tbase LIKE gbpmt.gbpmtplaz # Variable para guardar el numero de agencia
		END RECORD,
		#(@#)12-A FIN
       
		t4    RECORD LIKE cjctl.*,
                p2              ARRAY[25] OF RECORD
                                  avis          CHAR(40),
                                  usrr          CHAR(15),
                                  usrd          CHAR(15) 
                                END RECORD,
                #p25      ARRAY[50] OF RECORD      # Para reversion de Descuentos	#(@#)5-A
                p25      ARRAY[100] OF RECORD      # Para reversion de Descuentos	#(@#)5-A
                                ntra    INTEGER,
                                docu    CHAR(10),
                                cage    INTEGER,
                                nomb    CHAR(30)
                        END RECORD,
		g_rpta		   CHAR(1),
		g_modulo	   CHAR(25),
		g_mensaje	   CHAR(60),
                g_ind              SMALLINT,
#MAG
		i               SMALLINT,
                g_string        CHAR(79),
                g_ancho         SMALLINT,
                g_opcion        SMALLINT,
                g_spool         CHAR(10),
		t5     RECORD
                        dni     CHAR(8),
                        nomb    CHAR(40),
                        npre    CHAR(9),
                        cuot    SMALLINT,
                        impo    DECIMAL(14,2),
                        cmon    SMALLINT,
                        cloc    SMALLINT
                       END RECORD,	
                       
		#(@#)12-A INICIO
		g_new_fech DATE,   # Variable global Nueva fecha
		g_ruta CHAR(200), # ruta de salida del archivo
		g_text CHAR(500),   # Variable global cadena de texto general
		g_text_retail CHAR(500),   # Variable global cadena de texto retail
		g_const_guion CHAR(1),   # Variable global de caracter 'guion'
		g_const_dospuntos CHAR(1),   # Variable global de caracter 'dos puntos'
		g_const_log CHAR(20),   # Variable global de caracter extension archvo '.log'
		g_const_0 SMALLINT,   # Constante de valor 0
		g_const_1 SMALLINT,   # Constante de valor 1
		g_spool_2         CHAR(500), # Cadena de texto para nombre de archivo excel
		#(@#)12-A FIN
                #################################
                # variables generales NO BORRAR #
                #################################
                t0          RECORD LIKE gbpmt.*,
		x                  CHAR(1),
                g_user             CHAR(3),
                g_uaut             CHAR(3),
		g_flag		   SMALLINT,
                g_flag3            SMALLINT,
                g_flag4            SMALLINT,
                g_hora             CHAR(8),
		g_desc		   CHAR(40),
		g_nccd      LIKE cjctl.cjctltcvd,
		g_ncvd      LIKE cjctl.cjctltcvd,
		g_feri      SMALLINT,# (@#)7-A
		g_admin		   CHAR(3),
		g_reta	SMALLINT,  			# (@#)10-A
		g_flagRet SMALLINT  			# (@#)10-A
		,g_flag_hybris SMALLINT --#(@#)11-A
		


MAIN 
	IF NOT f0000_open_database_gb000() THEN EXIT PROGRAM END IF
	DEFER INTERRUPT
	OPTIONS ERROR LINE 23,
                INPUT WRAP
	SET LOCK MODE TO WAIT
        #WHENEVER ERROR CONTINUE
        OPEN FORM gb306_01 FROM "gb306a"
        DISPLAY FORM gb306_01
	LET g_user = arg_val(1)
        CALL f6050_buscar_empresa_gb306()
        CALL f6100_cabecera_gb306()
	IF NOT f0300_usuario_gb000(g_user) THEN
		ERROR "No tiene Autorizacion" SLEEP 2
		EXIT PROGRAM
        END IF        
	IF NOT f1000_clave_gb000(t0.gbpmtnomb,t0.gbpmtcusr,arg_val(2)) THEN
		ERROR " Acceso Denegado, llame a su proveedor de Software "
		SLEEP 2
		EXIT PROGRAM
	END IF
	IF f0700_vta_anuladas_gb306() THEN
		RUN "fglgo /u/tbase/ef753a"
	END IF
	#(@#)12-A INICIO
	CALL f100_inicializar_constantes()
	CALL f0251_preparar_cursores_gb306()
	#(@#)12-A FIN
        CALL f0300_proceso_gb306() 
	#(@#)12-A INICIO
	CALL f0010_libera_cursores_gb306()
	#(@#)12-A FIN
END MAIN

#(@#)12-A INICIO
FUNCTION f100_inicializar_constantes()
# Descripción: Inicializa contantes
	LET g_const_0 = 0
	LET g_const_0 = 1
	LET g_const_guion = "-"
	LET g_const_log = "LOG_gb306",g_const_guion
	LET g_const_dospuntos = ":"
	LET g_ruta = "/u/tbsfi/prueba/DarySanchez/SAI_programa_final_v3/"
END FUNCTION
#(@#)12-A FIN

#(@#)12-A INICIO
FUNCTION f0251_preparar_cursores_gb306()
# Descripción: Funcion que inicializa cursores
	DEFINE
		l_text	CHAR(1000) # Cadena de texto para llenar informacion de agencias

	LET l_text = " SELECT gbofinofi,gbofidesc,gbofihoss",
					" FROM tbsfi:gbofi ",
					" order by gbofinofi "
	PREPARE p_sql_2    FROM l_text
	DECLARE c_cursor_excel CURSOR FOR p_sql_2
END FUNCTION
#(@#)12-A FIN

#(@#)12-A INICIO
FUNCTION f0010_libera_cursores_gb306()
# Descripción: Función que libera cursores
	FREE c_cursor_excel
END FUNCTION
#(@#)12-A FIN

#(@#)12-A INICIO
FUNCTION f101_obtener_retail_gb306(l_tbase)
# Descripción: Obtiene retail de todas las agencias
	DEFINE
		l_tbase CHAR(100), # Variable para almacenar cadena tbase
		l_text	CHAR(1000), # Cadena de texto para llenar informacion de agencias
		l_plaz SMALLINT, # Variable codigo plaza
		l_retail CHAR(100), # Cadena Nombre retail
		l_desc	CHAR(500), # Nombre de oficina
		l_nofi	SMALLINT, # Numero de agencia
		l_ret_codi	SMALLINT, # Numero de retail
		l_ret_nomb CHAR(100), # Nombre retail
		l_nombre_salida CHAR(30) # Nombre salida log
	
		LET g_text = " SELECT gbpmtplaz,gbpmtnomb",
							" FROM ",l_tbase CLIPPED,":gbpmt " 
			WHENEVER sqlerror CONTINUE
			PREPARE pu02_act_fech_3 FROM g_text
			EXECUTE pu02_act_fech_3 INTO l_plaz,l_retail
			WHENEVER sqlerror STOP
		
		LET g_text_retail = " SELECT egbempcodi,egbempnomb",
								" FROM ",l_tbase CLIPPED,":egbemp "
			WHENEVER sqlerror CONTINUE
			PREPARE pu02_act_fech_4 FROM g_text_retail
			EXECUTE pu02_act_fech_4 INTO l_ret_codi,l_ret_nomb
			WHENEVER sqlerror STOP
		
	RETURN l_plaz,l_retail,l_ret_codi,l_ret_nomb
END FUNCTION
#(@#)12-A FIN
-------------------------------------------------------------------------


#################
# PROCESO CENTRAL
#################

#(@#)12-A INICIO
FUNCTION f0xxx_update_gb306()
# DESCRIPCION: Funcion que actualiza fecha de agencias
	DEFINE 
		l_text	CHAR(1000), # texto cadena para generacion de prepare
		l_desc	CHAR(500), # nombre oficina
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

	LET t0.gbpmtfdia = TODAY
	LET t6.new_fech = t0.gbpmtfdia
	LET t1.gbpmtfdia = TODAY
	LET t1.gbpmtfdia = g_new_fech
	LET g_spool_2 = l_nombre_salida_excel CLIPPED
	CALL f2100_detalle_excel_gb306()
END FUNCTION
#(@#)12-A FIN

#(@#)12-A INICIO
FUNCTION f2100_detalle_excel_gb306()
# Descripción: Función que genera el reporte para el formato excel.
	MESSAGE "Procesando archivo: ",g_ruta CLIPPED
	START REPORT imprime_rep_detallado TO g_spool_2
		CALL f5000_formato_excel_gb306()
	FINISH REPORT imprime_rep_detallado
END FUNCTION
#(@#)12-A FIN

#(@#)12-A INICIO
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
#(@#)12-A FIN


#(@#)12-A INICIO
FUNCTION f5000_formato_excel_gb306()
# Descripción: Función que da el formato xls al reporte.

	DEFINE  
		l_html	CHAR(15000), # Cadena de texto para llenado en celdas de excel
		l_tita_blue,l_tita_black,l_tita_yellow,l_tita_red,l_tita_green,l_tite,l_body	VARCHAR(255), # Estilos de formato para celdas
		l_time	DATETIME HOUR TO SECOND, # Hora actual
		l_text	CHAR(1000), # Cadena de texto para llenar informacion de agencias
		l_desc	CHAR(500), # Nombre de oficina
		l_sql1	CHAR(500), # Cadena de texto para cursor que recorrera agencias
		l_nofi	SMALLINT, # Numero de agencia
		l_tbase CHAR(100), # Variable para almacenar cadena tbase
		l_today DATE, # Fecha actual
		l_agencia_tbase SMALLINT, # Variable gbpmtplaz
		l_fecha_actual_tbase DATE, # Variable gbpmtfdia
		l_plaz SMALLINT, # Variable codigo plaza
		l_retail CHAR(100),  # Cadena Nombre retail
		l_ret_codi	SMALLINT, # Numero de retail
		l_ret_nomb CHAR(100) # Nombre retail

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
		LET l_html=l_html CLIPPED, "<td colspan = 13 " ,l_tita_blue CLIPPED,"text-align:CENTER;\"><b>","PARAMETROS DIARIOS - SAI","</b></td>"
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
	FETCH c_cursor_excel INTO l_nofi,l_desc,l_tbase
		WHILE STATUS <> NOTFOUND
			
			LET g_text = " SELECT gbpmtplaz,gbpmtfdia",
							" FROM ",l_tbase CLIPPED,":gbpmt"
			WHENEVER sqlerror CONTINUE
			PREPARE pu02_act_fech_2 FROM g_text
			EXECUTE pu02_act_fech_2 INTO l_agencia_tbase, l_fecha_actual_tbase
			WHENEVER sqlerror STOP
				
			IF l_fecha_actual_tbase < l_today THEN
				
				LET l_text = " UPDATE ",l_tbase CLIPPED,":gbpmt ",
								" SET gbpmtfdia = '",g_new_fech,"'"
				WHENEVER sqlerror CONTINUE
				PREPARE pu01_act_fech_3 FROM l_text
				EXECUTE pu01_act_fech_3
				WHENEVER sqlerror STOP
				
				CALL f101_obtener_retail_gb306(l_tbase CLIPPED)
				RETURNING l_plaz,l_retail,l_ret_codi,l_ret_nomb
				
				IF l_nofi = l_plaz THEN 
					IF SQLCA.SQLCODE < 0 THEN
						LET l_text = "NO SE ACTUALIZÓ FECHA EN AGENCIA EXTERNA "
						LET l_html="<tr>",
						" <td height=25  colspan= 1 ",l_tita_red CLIPPED,"vertical-align:middle;text-align:center;\">",l_ret_codi,"</td>",
						" <td height=25  colspan= 4 ",l_tita_red CLIPPED,"vertical-align:middle;text-align:center;\">",l_ret_nomb,"</td>",
						" <td height=25  colspan= 2 ",l_tita_red CLIPPED,"vertical-align:middle;text-align:center;\">",l_nofi,"</td>",
						" <td height=25  colspan= 4 ",l_tita_red CLIPPED,"vertical-align:middle;text-align:center;\">",l_retail CLIPPED,"</td>",
						" <td height=25  colspan= 4 ",l_tita_red CLIPPED,"vertical-align:middle;text-align:center;\">",l_text,"</td>",
						"</tr>"
					
					ELSE
					
						LET l_text = "SE ACTUALIZÓ FECHA EN AGENCIA EXTERNA "
						LET l_html="<tr>",
						" <td height=25  colspan= 1 ",l_tita_yellow CLIPPED,"vertical-align:middle;text-align:center;\">",l_ret_codi,"</td>",
						" <td height=25  colspan= 4 ",l_tita_yellow CLIPPED,"vertical-align:middle;text-align:center;\">",l_ret_nomb,"</td>",
						" <td height=25  colspan= 2 ",l_tita_yellow CLIPPED,"vertical-align:middle;text-align:center;\">",l_nofi,"</td>",
						" <td height=25  colspan= 4 ",l_tita_yellow CLIPPED,"vertical-align:middle;text-align:center;\">",l_retail CLIPPED,"</td>",
						" <td height=25  colspan= 4 ",l_tita_yellow CLIPPED,"vertical-align:middle;text-align:center;\">",l_text,"</td>",
						"</tr>"
					END IF
					OUTPUT TO REPORT imprime_rep_detallado(l_html)
				END IF
				
			ELSE
				
				CALL f101_obtener_retail_gb306(l_tbase CLIPPED)
				RETURNING l_plaz,l_retail,l_ret_codi,l_ret_nomb
				
				IF l_nofi = l_plaz THEN 
					LET l_text = "AGENCIA YA SE ENCUENTRA ACTUALIZADA A LA FECHA --> ",TODAY
					LET l_html="<tr>",
								" <td height=25  colspan= 1 ",l_tita_green CLIPPED,"vertical-align:middle;text-align:center;\">",l_ret_codi,"</td>",
								" <td height=25  colspan= 4 ",l_tita_green CLIPPED,"vertical-align:middle;text-align:center;\">",l_ret_nomb,"</td>",
								" <td height=25  colspan= 2 ",l_tita_green CLIPPED,"vertical-align:middle;text-align:center;\">",l_nofi,"</td>",
								" <td height=25  colspan= 4 ",l_tita_green CLIPPED,"vertical-align:middle;text-align:center;\">",l_retail CLIPPED,"</td>",
								" <td height=25  colspan= 4 ",l_tita_green CLIPPED,"vertical-align:middle;text-align:center;\">",l_text,"</td>",
								"</tr>"
					OUTPUT TO REPORT imprime_rep_detallado(l_html)
				END IF
			END IF

		FETCH c_cursor_excel INTO l_nofi,l_desc,l_tbase
		END WHILE
		CLOSE c_cursor_excel
END FUNCTION
#(@#)12-A FIN

FUNCTION f0300_proceso_gb306()

	DEFINE  l_com,l_ven     LIKE cjctl.cjctltcvd,
		l_fpro          DATE,
		l_hoy           DATE,
		l_abo	DECIMAL(10,2),
		l_time	DATE,	#CEMO(@#)3-A
		l1	RECORD
			  ntra	INTEGER,
			  tipo	CHAR(1),
			  cage	INTEGER,
			  ftra	DATE
			END RECORD,
		l2 RECORD LIKE gbhtc.*,  #(@#)7-A TIPO DE CAMBIO DE AYER 
		l_text	CHAR(1000), 	# (@#)10-A
		l_ffmes     DATE,	# (@#)10-A	
		g_flagEst SMALLINT,  	# (@#)10-A
		l_contVSD INTEGER	# (@#)10-A	

	CALL f6300_display_datos_gb306()

	LET int_flag = FALSE
        INITIALIZE t1.*,g_nccd,g_ncvd TO NULL
        #(@#)12-A INICIO
      	LET t0.gbpmtfdia = TODAY
			LET t6.new_fech = t0.gbpmtfdia
			LET t1.gbpmtfdia = TODAY
        #(@#)12-A FIN
        INPUT   BY NAME t1.*,g_nccd,g_ncvd,x WITHOUT DEFAULTS
		ON KEY (CONTROL-C,INTERRUPT)
		        LET int_flag = TRUE 
			EXIT INPUT
		BEFORE FIELD gbpmtfdia
			LET g_flag = FALSE
			LET g_flag3 = FALSE
			LET g_flag4 = FALSE
		BEFORE FIELD gbpmttcof
			IF t0.gbpmtplaz <> 0 THEN
				NEXT FIELD g_nccd
				#NEXT FIELD x
			END IF
                BEFORE FIELD gbpmttcco
                        IF t0.gbpmtplaz <> 0 THEN
                                NEXT FIELD g_nccd
                                #NEXT FIELD x
                        END IF
                BEFORE FIELD gbpmttcve
                        IF t0.gbpmtplaz <> 0 THEN
                                NEXT FIELD g_nccd
                                #NEXT FIELD x
                        END IF

                AFTER FIELD gbpmtfdia

                        IF t1.gbpmtfdia IS NULL THEN
                            NEXT FIELD gbpmtfdia
                        END IF
            #(@#)12-A INICIO                
				LET g_new_fech = t1.gbpmtfdia   
				DISPLAY g_new_fech  AT 4,66     
				CALL f0xxx_update_gb306()       
				#(@#)12-A FIN                   

                        IF t1.gbpmtfdia < t0.gbpmtfini THEN
                            ERROR "No puede ser menor a fecha inicial ",
				  "de la gestion presente"
                            NEXT FIELD gbpmtfdia
                        END IF
                #Inicio (@#)9-A
			IF YEAR(t1.gbpmtfdia)<> t0.gbpmtgest  THEN
				#ERROR "Ingrese una fecha del año actual:",t0.gbpmtgest,". Consultar con Contabilidad"
				ERROR "Ingrese una fecha del año actual:",t0.gbpmtgest,".  o esperar al cierre de Contabilidad"
				SLEEP 2
				NEXT FIELD gbpmtfdia
			END IF
		#Fin (@#)9-A
                #Inicio (@#)3-A
                	LET l_time=TODAY

                	IF t1.gbpmtfdia > l_time THEN
                            ERROR "Fecha ingresada no debe ser mayor a ", l_time
                            NEXT FIELD gbpmtfdia
                        END IF
                #Fin (@#)3-A
		
		    {	
		    IF t0.gbpmtplaz <> 0 THEN
			CALL leer_tipo_cambio_plaza_gb306(t0.gbpmtplaz,t1.gbpmtfdia)
				RETURNING t1.gbpmttcof,t1.gbpmttcco,t1.gbpmttcve,g_nccd,g_ncvd
			DISPLAY BY NAME t1.gbpmttcof
			DISPLAY BY NAME t1.gbpmttcco
			DISPLAY BY NAME t1.gbpmttcve
                        DISPLAY BY NAME g_nccd
                        DISPLAY BY NAME g_ncvd	
			#NEXT FIELD g_ncvd
			NEXT FIELD x 
		    END IF	
		    }
		    IF t0.gbpmtplaz <> 88 AND t0.gbpmtplaz <> 888 
			AND t0.gbpmtplaz <> 0 THEN
                        IF t1.gbpmtfdia < t0.gbpmtfdia THEN
                            ERROR "NO PERMITIDO CAMBIAR: Fecha Actual menor a ",
                                  "Fecha Anterior"
                                OPEN WINDOW wgb306d AT  8, 15
                                    WITH FORM "gb306d"
                                    ATTRIBUTE (REVERSE, FORM LINE 1)
                                OPTIONS INPUT NO WRAP
                                INPUT BY NAME g_rpta WITHOUT DEFAULTS
                                    ON KEY (INTERRUPT,CONTROL-C)
                                        LET int_flag = TRUE
                                        EXIT INPUT
                                    ON KEY (CONTROL-F)
                                        CALL f0400_autorizacion_ad800(g_user,
                                                16,1) RETURNING g_uaut,g_flag
                                        EXIT INPUT
                                END INPUT
                                CLOSE WINDOW wgb306d
                                ##
                                IF g_flag THEN
                                    LET int_flag = FALSE
                                ELSE
                                    LET int_flag = TRUE
                                    EXIT INPUT
                                END IF
                        END IF
                        IF t1.gbpmtfdia - t0.gbpmtfdia > 3 THEN
                            ERROR "PRECAUCION: Considerable diferencia ",
                                  "en el cambio de fecha!!!"
                        END IF
			##
			##  Verificar si es cambio de mes
			##
			##IF MONTH(t0.gbpmtfdia) <> MONTH(t1.gbpmtfdia) THEN			
			LET g_flagRet = 0						# (@#)10-A Inicio							
			LET g_flagEst = 0
			LET l_contVSD = 0
			LET l_text = NULL													
			LET l_text = "EXECUTE PROCEDURE ", f0020_buscar_bd_gb000(0,"S") CLIPPED , ":pa_ef_deshabilitacion_anulacion_venta(",
						f1012_Obtener_Valor_Cadena_gb000(0,t0.gbpmtplaz) CLIPPED,")" 		
			PREPARE p_spro_w1 FROM l_text
			DISPLAY l_text SLEEP 2
			EXECUTE p_spro_w1 INTO g_flagRet,g_flagEst										       
			SELECT LAST_DAY(gbpmtfdia) INTO l_ffmes  FROM gbpmt
			LET l_contVSD = f5000_ver_sindescarga_gb306()
			
			IF (l_ffmes = t0.gbpmtfdia) AND (MONTH(t0.gbpmtfdia) <> MONTH(t1.gbpmtfdia)) THEN
				IF l_contVSD > 0 THEN
						OPEN WINDOW wgb306b AT  8, 15 WITH FORM "gb306b"
						    ATTRIBUTE (REVERSE, FORM LINE 1)
						    OPTIONS INPUT NO WRAP
						    INPUT BY NAME g_rpta WITHOUT DEFAULTS
						    ON KEY (INTERRUPT,CONTROL-C)
							LET int_flag = TRUE	
							EXIT INPUT
						    ON KEY (CONTROL-F)
							CALL f0400_autorizacion_ad800(g_user,
								16,1) RETURNING g_uaut,g_flag
							EXIT INPUT
						END INPUT
						CLOSE WINDOW wgb306b
						IF g_flag THEN
						    LET int_flag = FALSE
						ELSE
						    LET int_flag = TRUE 
						    EXIT INPUT
						END IF
				END IF	
			END IF				
			
			IF g_flagRet = -1  THEN
				LET g_flagRet = g_flagEst
			END IF						# (@#)10-A Fin
			
			
			IF DAY(t0.gbpmtfdia) <> DAY(t1.gbpmtfdia) THEN
## HCC			   
			   IF g_flagRet = 0 AND l_contVSD > 0  AND t1.gbpmtfdia <> "01/10/2006" THEN # (@#)10-A
			   #IF f5000_ver_sindescarga_gb306() > 0 AND t1.gbpmtfdia <> "01/10/2006" THEN # (@#)10-A
						OPEN WINDOW wgb306b AT  8, 15
						    WITH FORM "gb306b"
						    ATTRIBUTE (REVERSE, FORM LINE 1)
						OPTIONS INPUT NO WRAP
						INPUT BY NAME g_rpta WITHOUT DEFAULTS
						    ON KEY (INTERRUPT,CONTROL-C)
							LET int_flag = TRUE
							EXIT INPUT
						    ON KEY (CONTROL-F)
							CALL f0400_autorizacion_ad800(g_user,
								16,1) RETURNING g_uaut,g_flag
							EXIT INPUT
						END INPUT
						CLOSE WINDOW wgb306b
						##
						IF g_flag THEN
						    LET int_flag = FALSE
						ELSE
						    LET int_flag = TRUE 
						    EXIT INPUT
						END IF
			    END IF
			END IF 


			###GBT
				
				
            IF t1.gbpmtfdia <> t0.gbpmtfdia THEN
			   IF f9700_postearmod_gb306() THEN
				OPEN WINDOW wgb306e AT  8, 15
				    WITH FORM "gb306e"
				    ATTRIBUTE (REVERSE, FORM LINE 1)
				OPTIONS INPUT NO WRAP
				DISPLAY BY NAME g_modulo
				INPUT BY NAME g_rpta WITHOUT DEFAULTS
				    ON KEY (INTERRUPT,CONTROL-C)
					LET int_flag = TRUE
					EXIT INPUT
				    ON KEY (CONTROL-F)
					CALL f0400_autorizacion_ad800(g_user,
						16,1) RETURNING g_uaut,g_flag3
					EXIT INPUT
				END INPUT
				CLOSE WINDOW wgb306e
				IF g_flag3 THEN
				    LET int_flag = FALSE
				ELSE
				    LET int_flag = TRUE 
				    EXIT INPUT
				END IF
			   END IF
			END IF 

			IF MONTH(t0.gbpmtfdia) <> MONTH(t1.gbpmtfdia) THEN
				IF f9800_stritar_gb306() AND t1.gbpmtfdia <> "01/10/2006" THEN
					OPEN WINDOW wgb306f AT  8, 15
					    WITH FORM "gb306f"
					    ATTRIBUTE (REVERSE, FORM LINE 1)
					OPTIONS INPUT NO WRAP
					DISPLAY BY NAME g_mensaje
					INPUT BY NAME g_rpta WITHOUT DEFAULTS
				    		ON KEY (INTERRUPT,CONTROL-C)
							LET int_flag = TRUE
							EXIT INPUT
				    		ON KEY (CONTROL-F)
							CALL f0400_autorizacion_ad800(g_user,
						16,1) RETURNING g_uaut,g_flag4

						EXIT INPUT
					END INPUT
					CLOSE WINDOW wgb306f
					IF g_flag4 THEN
				    		LET int_flag = FALSE
					ELSE
				    		LET int_flag = TRUE 
				    		EXIT INPUT
					END IF
				END IF
			END IF

		    END IF

					LET g_feri = 0 #(@#)7-A
                    IF t0.gbpmtplaz <> 0 THEN
                        CALL leer_tipo_cambio_plaza_gb306(t0.gbpmtplaz,t1.gbpmtfdia)
                                RETURNING t1.gbpmttcof,t1.gbpmttcco,t1.gbpmttcve,g_nccd,g_ncvd
                        
                        #Inicio (@#)7-A
						INITIALIZE l2.* TO NULL
						IF t1.gbpmttcof IS NULL OR t1.gbpmttcof = 0 THEN
							LET g_feri = f1600_dia_feriado_gb306(t1.gbpmtfdia)
							IF g_feri THEN
								ERROR "Hoy es feriado, se tomara tipo cambio de ayer"
								SLEEP 2
								SELECT * INTO l2.* 
									FROM gbhtc 
									WHERE gbhtcfech = t1.gbpmtfdia - 1
							    IF STATUS = NOTFOUND THEN
							    	ERROR "No existe tipo de cambio antes del feriado"
							    END IF
							    
							    LET t1.gbpmttcof = l2.gbhtctcof
							    LET t1.gbpmttcco = l2.gbhtctcco
							    LET t1.gbpmttcve = l2.gbhtctcve
							   
							END IF
						END IF
						#Fin (@#)7-A
						
                        DISPLAY BY NAME t1.gbpmttcof
                        DISPLAY BY NAME t1.gbpmttcco
                        DISPLAY BY NAME t1.gbpmttcve
                        DISPLAY BY NAME g_nccd
                        DISPLAY BY NAME g_ncvd
                        #NEXT FIELD g_ncvd
                        NEXT FIELD x
                    END IF
		{
		##--> SOLO PUEDE CAMBIARLO LA AGENCIA DE LIMA
		IF t0.gbpmtplaz = 0 THEN
			IF NOT verificar_hist_con_fecha(t1.gbpmtfdia) THEN
    	                        CALL leer_tipo_cambio_plaza_gb306(t0.gbpmtplaz,t1.gbpmtfdia)
                                	RETURNING t1.gbpmttcof,t1.gbpmttcco,t1.gbpmttcve,g_nccd,g_ncvd
		                DISPLAY BY NAME t1.gbpmttcof
	                	DISPLAY BY NAME t1.gbpmttcco
                        	DISPLAY BY NAME t1.gbpmttcve
                        	DISPLAY BY NAME g_nccd
                        	DISPLAY BY NAME g_ncvd
			END IF
			NEXT FIELD gbpmttcof 		
		END IF
                }
                AFTER FIELD gbpmttcof
                		#inicio (@#)2-A
                        IF t1.gbpmttcof IS NULL OR t1.gbpmttcof = 0 THEN
                        #fin (@#)2-A
                            LET t1.gbpmttcof = t0.gbpmttcof
                            DISPLAY BY NAME t1.gbpmttcof
                        END IF
                        IF t1.gbpmttcof < t0.gbpmttcof THEN
                            ERROR "PRECAUCION: Cambio Oficial menor a ",
                                  "Cambio Anterior"
                        END IF
                        IF t1.gbpmttcof - t0.gbpmttcof > 0.05 THEN
                            ERROR "PRECAUCION: Considerable diferencia ",
                                  "en el nuevo Cambio Oficial!!!"
                        END IF

                AFTER FIELD gbpmttcco
                		#inicio (@#)2-A
                        IF t1.gbpmttcco IS NULL OR t1.gbpmttcco = 0 THEN
                        #fin (@#)2-A
                            LET t1.gbpmttcco = t0.gbpmttcco
                            DISPLAY BY NAME t1.gbpmttcco
                        END IF
                        IF t1.gbpmttcco < t0.gbpmttcco THEN
                            ERROR "PRECAUCION: Tipo de Cambio Compra ",
                                  "menor a Cambio Anterior"
                        END IF
                        IF t1.gbpmttcco - t0.gbpmttcco > 0.05 THEN
                            ERROR "PRECAUCION: Considerable diferencia ",
                                  "en el nuevo Tipo de Cambio Compra!!!"
                        END IF

                AFTER FIELD gbpmttcve
                		#inicio (@#)2-A
                        IF t1.gbpmttcve IS NULL OR t1.gbpmttcve = 0 THEN
                        #fin (@#)2-A
                            LET t1.gbpmttcve = t0.gbpmttcve
                            DISPLAY BY NAME t1.gbpmttcve
                        END IF
                        IF t1.gbpmttcve < t0.gbpmttcve THEN
                            ERROR "PRECAUCION: Tipo de Cambio Venta ",
                                  "menor a Cambio Anterior"
                        END IF
                        IF t1.gbpmttcve - t0.gbpmttcve > 0.05 THEN
                            ERROR "PRECAUCION: Considerable diferencia ",
                                  "en el nuevo Tipo de Cambio Venta!!!"
                        END IF

		BEFORE FIELD g_nccd
			LET l_com = t4.cjctltccd
		AFTER FIELD g_nccd
			IF g_admin IS NOT NULL THEN
			   IF g_user = g_admin THEN
			       IF g_nccd IS NULL THEN
                               	  LET g_nccd = t4.cjctltccd 
                            	  DISPLAY BY NAME g_nccd
                               END IF
			       IF g_nccd < t4.cjctltccd THEN
                                   ERROR "PRECAUCION: Tipo de Cambio Compra ",
                                     "menor a Cambio Anterior"
                               END IF
                               IF g_nccd  - t4.cjctltccd  > 0.05 THEN
                                  ERROR "PRECAUCION: Considerable diferencia ",
                                    "en el nuevo Tipo de Cambio Compra!!!"
                               END IF
                           ELSE
                               IF l_com <> g_nccd  THEN
                                  ERROR "Usuario no autorizado a cambiar T/C"
                                  LET g_nccd = l_com
                                  DISPLAY BY NAME g_nccd
                               END IF
                           END IF
			ELSE
                           ERROR "Estos tipos de cambios solo puede ",
				 " cambiarlos el ADMINISTRADOR ¢ GERENTE"
			END IF
		BEFORE FIELD g_ncvd 
                        LET l_ven = t4.cjctltcvd
                AFTER  FIELD g_ncvd 
			IF g_admin IS NOT NULL THEN
                           IF g_user = g_admin THEN
			       IF g_ncvd IS NULL THEN
                                  LET g_ncvd = t4.cjctltcvd
                                  DISPLAY BY NAME g_ncvd
                               END IF
			       IF g_ncvd < t4.cjctltcvd THEN
                                   ERROR "PRECAUCION: Tipo de Cambio Venta ",
                                     "menor a Cambio Anterior" 
                               END IF 
                               IF g_ncvd  - t4.cjctltcvd  > 0.05 THEN 
                                  ERROR "PRECAUCION: Considerable diferencia ", 
                                    "en el nuevo Tipo de Cambio Venta!!!" 
                               END IF
                           ELSE
                               IF l_ven <> g_ncvd THEN
                                  ERROR "Usuario no autorizado a cambiar T/C"
                                  LET g_ncvd = l_ven
                                  DISPLAY BY NAME g_ncvd
                               END IF
                           END IF
			ELSE
                           ERROR "Estos tipos de cambios solo puede ",
				 " cambiarlos el ADMINISTRADOR ¢ GERENTE"
			END IF
                        MESSAGE " <ESC> para grabar..."
			ERROR " "

		BEFORE FIELD x
                        MESSAGE " <ESC> para grabar..."
                        ERROR " "
			
		AFTER FIELD x   
						
						#inicio (@#)2-A
                        IF t1.gbpmttcof IS NULL OR t1.gbpmttcof = 0 THEN
                        #fin (@#)2-A
                            ERROR "No Existe un Tipo de Cambio a la Fecha Ingresada"
                            #NEXT FIELD gbpmttcof
                            NEXT FIELD gbpmtfdia
                        END IF
                        #inicio (@#)2-A
                        IF t1.gbpmttcco IS NULL OR t1.gbpmttcco = 0 THEN
                        #fin (@#)2-A
                            ERROR "No Existe un Tipo de Cambio a la Fecha Ingresada"
                            #NEXT FIELD gbpmttcco
                            NEXT FIELD gbpmtfdia
                        END IF
                        #inicio (@#)2-A
                        IF t1.gbpmttcve IS NULL OR t1.gbpmttcve = 0 THEN
                        #fin (@#)2-A
                            ERROR "No Existe un Tipo de Cambio a la Fecha Ingresada"
                            #NEXT FIELD gbpmttcve
                            NEXT FIELD gbpmtfdia
                        END IF

                        MESSAGE " <ESC> para grabar..."
                        ERROR " "
			
                AFTER INPUT
			{
                        IF t1.gbpmttcof IS NULL THEN
			    ERROR "No Existe un Tipo de Cambio a la Fecha Ingresada"	
                            #NEXT FIELD gbpmttcof
                            NEXT FIELD x
                        END IF
                        IF t1.gbpmttcco IS NULL THEN
                            ERROR "No Existe un Tipo de Cambio a la Fecha Ingresada"			    	
                            #NEXT FIELD gbpmttcco
                            NEXT FIELD x
                        END IF
                        IF t1.gbpmttcve IS NULL THEN
                            ERROR "No Existe un Tipo de Cambio a la Fecha Ingresada"
                            #NEXT FIELD gbpmttcve
                            NEXT FIELD x
                        END IF
			}
			IF g_user = g_admin THEN
                            IF g_nccd IS NULL THEN
                                ERROR "Ingrese el tipo de cambio de divisas"
                                NEXT FIELD g_nccd
                            END IF
			    IF g_ncvd IS NULL THEN
                                ERROR "Ingrese el tipo de cambio de divisas"
                                NEXT FIELD g_ncvd
                            END IF
			END IF
                        MESSAGE " "
	END INPUT
	IF int_flag THEN
            RETURN
        END IF

        CALL f2000_modificar_gb306()
	##-----------------Deshabilitando modulos------------------------------#
	IF t0.gbpmtplaz <> 88 AND t0.gbpmtplaz <> 888 
		AND t0.gbpmtplaz <> 0 THEN
	    DELETE FROM efmop
	    INSERT INTO efmop VALUES(1," ")
	    INSERT INTO efmop VALUES(2," ")
	    INSERT INTO efmop VALUES(14," ")
	    INSERT INTO efmop VALUES(98," ")
	    INSERT INTO efmop VALUES(99," ")
	END IF
	##--- Verificacion de preventas no facturadas ---##
	#BEGIN WORK
	MESSAGE "LIMPIANDO PREVENTAS..."	
	SELECT vtprvntra,vtprvtipo,vtprvcage,vtprvftra 
	FROM vtprv
	WHERE vtprvstat < 2 AND vtprvftra <= t0.gbpmtfdia
	  AND vtprvcloc <> 88
	INTO TEMP tmp_rever WITH NO LOG

	DECLARE q_lprev CURSOR WITH HOLD FOR
	    SELECT * FROM tmp_rever


	FOREACH q_lprev INTO l1.*
		IF l1.tipo = "C" THEN
		    CALL f1500_anula_preventa_gb306(l1.ntra,l1.tipo)
		ELSE
		    IF t0.gbpmtfdia-l1.ftra > 3 THEN
			SELECT sum(cctrnimpo)*-1 INTO l_abo
			FROM cctrn
			WHERE cctrnncta = l1.cage
			AND cctrnftra >= l1.ftra
			IF l_abo <= 0 THEN
			    CALL f1500_anula_preventa_gb306(l1.ntra,l1.tipo)
			END IF
		    END IF
		END IF
	END FOREACH
{
	IF t0.gbpmtplaz <> 88 AND  t0.gbpmtplaz <> 888 THEN
            CALL f5500_ver_chklist_gb306()
	END IF	
}
        ##
END FUNCTION

###########################
# MODIFICACION DE REGISTROS
###########################

FUNCTION f2000_modificar_gb306()
	DEFINE l_text	CHAR(500),
	       l_plaz	SMALLINT,
	       l_host	CHAR(30)		

        LET g_hora = TIME
        BEGIN WORK
        ##########################################	
        UPDATE gbpmt SET gbpmtfdia = t1.gbpmtfdia,
                         gbpmttcof = t1.gbpmttcof,
                         gbpmttcco = t1.gbpmttcco,
                         gbpmttcve = t1.gbpmttcve
        IF NOT f0500_error_gb000(status,"gbpmt") THEN
            	ROLLBACK WORK
            	RETURN
        END IF
	##########################################

	###################################################
	## SE INGRESA A TODAS LAS PLAZAS SOLO DE LA CENTRAL
	## LA ADMINISTRADORA -- SRA. MARIETA
	###################################################	
	{
	IF g_user = g_admin AND t0.gbpmtplaz = 88 THEN
            DECLARE q_ofi2 CURSOR FOR
            SELECT gbofinofi
                FROM tbsfi:gbofi		
		ORDER BY gbofinofi
	    MESSAGE "Actualizando los Datos en toda las agencias...cjtctl"		
	    SLEEP 1	
	    FOREACH q_ofi2 INTO l_plaz
                LET l_host = f0020_buscar_bd_gb000(l_plaz,"S")
		LET l_text = " UPDATE ",l_host CLIPPED,":cjctl ",
		             " SET cjctltccd = ",g_nccd,",",
			     " cjctltcvd = ",g_ncvd	
                PREPARE s_s1 FROM l_text
                EXECUTE s_s1		
		IF NOT f0500_error_gb000(status,"cjctl") THEN
			ERROR "No se pudo ingresar los datos en la tabla cjctl"
                	ROLLBACK WORK
                	RETURN
            	END IF
	    END FOREACH
	    MESSAGE ""	
	END IF
	}
#	INSERT INTO gbhtc VALUES (t1.gbpmtfdia,t1.gbpmttcof,t1.gbpmttcco,
#                                  t1.gbpmttcve,g_user,g_hora,TODAY)
#        IF NOT f0500_error_gb000(status,"gbhtc") THEN
#            	ROLLBACK WORK
#            	RETURN
#        END IF
    
    #Inicio (@#)7-A 
    IF g_feri THEN  #Solo ingresa cuando es feriado y no hubo tipo de cambio
    	INSERT INTO gbhtc VALUES (t1.gbpmtfdia,t1.gbpmttcof,t1.gbpmttcco,
                                  t1.gbpmttcve,g_user,g_hora,TODAY)
        IF NOT f0500_error_gb000(status,"gbhtc") THEN
            	ROLLBACK WORK
            	RETURN
        END IF	
    END IF
    #Fin (@#)7-A 
	COMMIT WORK
#MAG
	IF t0.gbpmtplaz  <> 88 AND t0.gbpmtplaz  <> 888 
		AND t0.gbpmtplaz <> 0 THEN
	    IF t1.gbpmtfdia <> t0.gbpmtfdia THEN
		CALL f0150_envia_lista_cobranza_itinerante_efe()	
	    END IF
        END IF

END FUNCTION

#########################
## RUTINAS DE SANTIAGO ##
#########################

FUNCTION verificar_hist_con_fecha(l_fecha)
	DEFINE 	l_fecha		DATE,
		l_cont		SMALLINT

	SELECT COUNT(*) INTO l_cont
		FROM gbhtc
		WHERE gbhtcfech = l_fecha 	

	IF l_cont > 0 THEN
	     RETURN FALSE
	ELSE
	     RETURN TRUE
	END IF
END FUNCTION

FUNCTION leer_tipo_cambio_plaza_gb306(l_plaz,l_fech )
	DEFINE l_plaz	SMALLINT,
	       l_text   CHAR(500),
	       l_host	CHAR(25),
	       l_fech   DATE,
	       l_tcof   DECIMAL(7,3),
	       l_tcco   DECIMAL(7,3),
	       l_tcve   DECIMAL(7,3),
	       l_dccd   DECIMAL(7,3),
	       l_dcvd   DECIMAL(7,3)

	#############
	## TIPOCAMB #
	#############
	IF l_plaz = 888 THEN
		LET l_host = "tbase888"	
	ELSE
		LET l_host = f0020_buscar_bd_gb000(l_plaz,"S")
	END IF

	LET l_text = "SELECT FIRST 1 gbhtctcof,gbhtctcco,gbhtctcve ",
		     "FROM ",l_host CLIPPED,":gbhtc ",
		     " WHERE gbhtcfech = '",l_fech,"'"	
        PREPARE l_gbhtc FROM l_text
        DECLARE q_curs3 CURSOR FOR l_gbhtc

        FOREACH q_curs3 INTO l_tcof,l_tcco,l_tcve END FOREACH
        IF l_tcof IS NULL THEN
                LET l_tcof = 0
        END IF
        IF l_tcco IS NULL THEN
                LET l_tcco = 0
        END IF 
        IF l_tcve IS NULL THEN
                LET l_tcve = 0
        END if
	#############
	## DIVISAS ##
	#############	
        LET l_text = "SELECT FIRST 1 cjctltccd,cjctltcvd ",
                     "FROM ",l_host CLIPPED,":cjctl "
        PREPARE l_gbhtd FROM l_text
        DECLARE q_curs43 CURSOR FOR l_gbhtd
        FOREACH q_curs43 INTO l_dccd,l_dcvd END FOREACH

        IF l_dccd IS NULL THEN
                LET l_dccd = 0
        END IF 
        IF l_dcvd IS NULL THEN
                LET l_dcvd = 0
        END IF 
                        
	RETURN l_tcof,l_tcco,l_tcve,l_dccd,l_dcvd

END FUNCTION

###############################################
# FUNCIONES DE ENVIO DE COBRANZAS ITINERANTES
# A TODAS LA SUCURSALES 
# MAG
#############################################3
FUNCTION f1010_establece_gspool_ef582()
        DEFINE          cloc    SMALLINT

        SELECT MIN(vtloccloc) INTO cloc FROM vtloc
        LET g_spool = cloc USING "&&&","efe.txt"
                                #extension: cobranzas itinerantes
END FUNCTION
FUNCTION f0250_declara_itinerantes_ef582()
        DECLARE q_cursor CURSOR FOR
                SELECT  cjtitdni as dni,
                        cjtrnnomb as nomb,
                        cjtitnpre as ncre,
                        cjtitcuot as cuot,
                        cjtrnimpo as imp,
                        cjtrncmon as cmon,
                        cjtitcloc as cloc
                FROM cjtit,cjtrn
                WHERE   cjtitntra = cjtrnntra AND
                        cjtrnftra =  t0.gbpmtfdia
                        AND cjtrnstat <> 9
                        ORDER BY cjtitcloc,cjtrnnomb
END FUNCTION
FUNCTION f7000_crear_temporal_ef582()
        CREATE TEMP TABLE tmp_cjitl #listado de locales destino del cobro
                (
                tmp_cjitlcloc   SMALLINT,
                tmp_cjitldesc   CHAR(20)
                )
        LOAD FROM "/u/tbase/LSUCURSALES.TXT"
                INSERT INTO tmp_cjitl
END FUNCTION
FUNCTION f0150_envia_lista_cobranza_itinerante_efe()
        DEFINE  comando_shell   CHAR(50)
        
        CALL f7000_crear_temporal_ef582()
        CALL f0250_declara_itinerantes_ef582()
        CALL f1010_establece_gspool_ef582()
        IF f1000_impreso_ef582() = 1 THEN
              MESSAGE "Reenviando..."
              LET comando_shell = "mv ", g_spool," /u/trabajo/."
              RUN comando_shell
              LET comando_shell ="itinesai " ,g_spool CLIPPED
              RUN comando_shell
	      LET comando_shell = "rm ", " /u/trabajo/", g_spool
              RUN comando_shell
              MESSAGE " "
        END IF
	DROP TABLE tmp_cjitl
END FUNCTION
FUNCTION f1000_impreso_ef582()
        DEFINE  sw_envio        SMALLINT
        LET sw_envio = -1
        START REPORT f1100_proceso_impr_ef582 TO g_spool
        FOREACH q_cursor INTO t5.*
                OUTPUT TO REPORT f1100_proceso_impr_ef582(t5.*)
                LET sw_envio = 1
        END FOREACH
        FINISH REPORT f1100_proceso_impr_ef582
        RETURN sw_envio
END FUNCTION
REPORT f1100_proceso_impr_ef582(r)
        DEFINE  r       RECORD
                        dni     CHAR(8),
                        nomb    CHAR(40),
                        npre    CHAR(9),
                        cuot    SMALLINT,
                        impo    DECIMAL(14,2),
                        cmon    SMALLINT,
                        cloc    SMALLINT
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
                LET g_string = t0.gbpmtnomb CLIPPED
                PRINT ASCII 15
                PRINT COLUMN  1,"MODULO EFE",
                      COLUMN ((g_ancho-length(g_string))/2),g_string CLIPPED,
                      COLUMN (g_ancho-9),"PAG: ",PAGENO USING "<<<<"
		LET g_string = "RELACION DE COBRANZAS ITINERANTES" CLIPPED
                PRINT COLUMN  1,TIME CLIPPED,
                      COLUMN ((g_ancho-length(g_string))/2),g_string CLIPPED,
                      COLUMN (g_ancho-9),TODAY USING "dd-mm-yyyy"
                LET g_string ="Al ", t0.gbpmtfdia CLIPPED
                PRINT COLUMN  1,"gb306.4gl",
                      COLUMN  ((g_ancho-length(g_string))/2),g_string CLIPPED
                SKIP 1 LINE

        BEFORE GROUP OF r.cloc
                FOR i=16 TO 114 PRINT COLUMN i, "="; END FOR PRINT "="
                PRINT COLUMN 16, "Cobranza de Credito correspondiente a: ",
                                f5000_buscar_sucursal_ef582(r.cloc)
                PRINT COLUMN 16, "DNI",
                      COLUMN 27,"CLIENTE",
                      COLUMN 73,"No PREST.",
                      COLUMN 84,"No CUOTA" ,
                      COLUMN 97,"IMPORTE"
                FOR i=16 TO 114 PRINT COLUMN i,"="; END FOR PRINT "="
        ON EVERY ROW
                PRINT COLUMN 16,r.dni CLIPPED,
                      COLUMN 27,r.nomb [1,40] CLIPPED,
		                            COLUMN 73,r.npre CLIPPED,
                      COLUMN 90,r.cuot USING "##";
                IF r.cmon = 1 THEN
                        PRINT COLUMN 97,"S/.";
                ELSE
                        PRINT COLUMN 97,"US$";
                END IF
                PRINT COLUMN 101,r.impo USING "#,###,###.##"

        PAGE TRAILER
                PRINT ASCII 18
        AFTER  GROUP OF r.cloc
                SKIP 1 LINE
END REPORT
FUNCTION f5000_buscar_sucursal_ef582(cloc)
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
########################################
# VERIFICACION DE PRODUCTOS POR ENTREGAR
########################################
FUNCTION f5000_ver_sindescarga_gb306()
        DEFINE  l_numt  SMALLINT

	#IF t0.gbpmtplaz <> 50 THEN	# (@#)10-A 	
        SELECT COUNT(DISTINCT vtnvhntra) INTO l_numt
        FROM vtnvh, vtnva
        WHERE vtnvhftra <= t0.gbpmtfdia
        AND vtnvhtnve in (2,4)
        AND vtnvhstat = 0
        AND vtnvhntra = vtnvantra
        AND vtnvacven > vtnvacent 
        #-----
        AND vtnvhntra NOT IN (SELECT vtnvcntra FROM vtnvc WHERE vtnvcmrcb=0 AND vtnvcagen=t0.gbpmtplaz AND vtnvcfcad>t0.gbpmtfdia)
        #-----
	#AND vtnvhntra <> 34210  # (@#)10-A
        IF l_numt > 0 THEN
                RETURN l_numt
        END IF

        #Verificar si tiene facturacion en OF.Princ.
        SELECT COUNT(DISTINCT vtnvhntra) INTO l_numt
        FROM tbase088:vtnvh, tbase088:vtnva
        WHERE vtnvhftra <= t0.gbpmtfdia
        AND vtnvhtnve in (2,4)
        AND vtnvhstat = 0
        AND vtnvhntra = vtnvantra
        AND vtnvacven > vtnvacent
        #----------------------
        AND vtnvhntra NOT IN (SELECT vtnvcntra FROM vtnvc WHERE vtnvcmrcb=0 AND vtnvcagen=t0.gbpmtplaz AND vtnvcfcad>t0.gbpmtfdia)
        #----------------------
        AND vtnvhtorg IN (SELECT vtprvntra
                                    FROM tbase088:vtprv
                                    WHERE vtprvcloc in (select vtloccloc from vtloc) )# (@#)8-A
                                    #WHERE vtprvcloc= t0.gbpmtplaz)# (@#)8-A

        IF l_numt > 0 THEN
                ERROR "Ventas Sin Descarga de Of. Principal",
                " Revisar Correo"
        END IF
        #END IF			# (@#)10-A
        RETURN l_numt
END FUNCTION


FUNCTION f5550_query1_gb306()
    	DECLARE q_curs1 CURSOR FOR 
	SELECT * FROM efchl
	 WHERE efchltipo = 1

    	RETURN
END FUNCTION

FUNCTION f5550_query2_gb306()
        DECLARE q_curs2 CURSOR FOR
        SELECT * FROM efchl
         WHERE efchltipo = 2

        RETURN
END FUNCTION

FUNCTION f5500_ver_chklist_gb306()
	DEFINE    l_diahoy    SMALLINT,
		  l_numdia    SMALLINT,
		  l_tmp       SMALLINT,
		  l_tmpfech   DATE,
		  l_cont      SMALLINT,
                  l_reg       SMALLINT

	LET l_cont = 0

	CALL f5550_query1_gb306()
        LET l_diahoy = DAY(t1.gbpmtfdia)
        LET l_numdia = WEEKDAY(t1.gbpmtfdia)
        LET l_tmp    = l_diahoy + 1

	##VERIFICANDO AVISOS CUANDO TIPO = 1 (DIA ACTUAL)
        FOREACH q_curs1 INTO t2.*
	  CASE 
	      WHEN t2.efchlnumd = l_diahoy                   ## Coincide 
							     ## el dia del
                    LET l_cont = l_cont + 1
		    LET p2[l_cont].avis = t2.efchlavis
		    LET p2[l_cont].usrr = t2.efchlusrr
		    LET p2[l_cont].usrd = t2.efchlusrd
              WHEN t2.efchlnumd <> l_diahoy                  ## NO Coincide
                                                             ## C/el dia de HOY
		    LET l_reg = 0
                    IF (t2.efchlnumd + 1) =  l_diahoy  THEN
                       SELECT count(*) INTO l_reg
                          FROM gbhtc 
			  WHERE DAY(gbhtcfech) = (t2.efchlnumd)
			     AND MONTH(gbhtcfech) = MONTH(t1.gbpmtfdia) 
			     AND YEAR(gbhtcfech) = YEAR(t1.gbpmtfdia) 

		       IF l_reg = 0 THEN  
                          LET l_cont = l_cont + 1
                          LET p2[l_cont].avis = t2.efchlavis
                          LET p2[l_cont].usrr = t2.efchlusrr
                          LET p2[l_cont].usrd = t2.efchlusrd
		       END IF
		    END IF

							# SAI con el dia d'Aviso
	      WHEN  l_diahoy =  (t2.efchlnumd + 1)      ##Verificando que el dia
            	      LET l_tmpfech = t1.gbpmtfdia - 1  # de ayer no es domingo
		      LET l_tmp = WEEKDAY(l_tmpfech)
                      IF l_tmp = 0 THEN
                    	 LET l_cont = l_cont + 1
                    	 LET p2[l_cont].avis = t2.efchlavis
                    	 LET p2[l_cont].usrr = t2.efchlusrr
                    	 LET p2[l_cont].usrd = t2.efchlusrd
		      END IF
	  END CASE	
        END FOREACH
	
	##VERIFICANDO AVISOS CUANDO TIPO = 2 (DIA DE LA SEMANA: L-V)

        CALL f5550_query2_gb306()

        ##VERIFICANDO AVISOS CUANDO TIPO = 1 (DIA ACTUAL)
        FOREACH q_curs2 INTO t2.*
          CASE
              WHEN l_numdia = t2.efchlnumd        ## Coincida el dia d la semana
				                  # con tareas del Chklist
                    LET l_cont = l_cont + 1
                    LET p2[l_cont].avis = t2.efchlavis
                    LET p2[l_cont].usrr = t2.efchlusrr
                    LET p2[l_cont].usrd = t2.efchlusrd
              OTHERWISE                                ##Verificando que el dia
                      LET l_reg = 0
                      LET l_tmpfech = t1.gbpmtfdia - 1 # de ayer no hubo TC
                      LET l_tmp = WEEKDAY(l_tmpfech)
                      SELECT count(*) INTO l_reg 
			 FROM gbhtc WHERE gbhtcfech = l_tmpfech
                      IF l_reg = 0 AND l_tmp  = t2.efchlnumd  THEN
                    	 LET l_cont = l_cont + 1
                    	 LET p2[l_cont].avis = t2.efchlavis
                    	 LET p2[l_cont].usrr = t2.efchlusrr
                    	 LET p2[l_cont].usrd = t2.efchlusrd
                      END IF
          END CASE
        END FOREACH
      	LET l_cont = l_cont + 1
        LET p2[l_cont].avis = "ENVIAR rd.Z "
        LET p2[l_cont].usrr = "AGENCIAS"
        LET p2[l_cont].usrd = "VICKY CABEZAS"

        LET l_cont = l_cont + 1
        LET p2[l_cont].avis = "ENVIAR trans.Z SI HAY VTAS PERSONAL EFE"
        LET p2[l_cont].usrr = "AGENCIAS"
        LET p2[l_cont].usrd = "JAVIER VIDUAR"

        LET l_cont = l_cont + 1
        LET p2[l_cont].avis = "NO OLVIDE INCORPORAR trans.Z RECIBIDOS"
        LET p2[l_cont].usrr = "AGENCIAS"
        LET p2[l_cont].usrd = "IMPORTANTE!!"

	CALL set_count(l_cont)

	## MOSTRANDO EL CKKLIST DEL DIA

        OPEN WINDOW wgb306c AT  7, 2 
          WITH FORM "gb306c"
          ATTRIBUTE (REVERSE, FORM LINE 1)
          OPTIONS INPUT NO WRAP

        DISPLAY ARRAY p2 TO s2.*
            ON KEY (CONTROL-C,INTERRUPT)
                LET int_flag = FALSE
                EXIT DISPLAY
        END DISPLAY

        CLOSE WINDOW wgb306c
        #CALL f6200_crea_efppg_ef341()
        #CALL f0300_proceso_ef341()

END FUNCTION

FUNCTION f9700_postearmod_gb306()
	DEFINE l_cjtcn, l_vttcn, l_intcn,
		l_cctcn, l_cptcn, l_pptcn,
		l_cotcn, l_pctcn, l_tstcn SMALLINT,
		l_fecha	DATE

	LET l_fecha = MDY(MONTH(t0.gbpmtfdia),1,YEAR(t0.gbpmtfdia))

	DISPLAY "Revisando Posteo de Caja " TO g_desc	
	SELECT COUNT(*) INTO l_cjtcn
	FROM cjtcn
	WHERE cjtcnftra BETWEEN l_fecha AND t0.gbpmtfdia
	AND   cjtcnpost = 0
	IF l_cjtcn > 0 THEN  
		 LET g_modulo = "Caja"
		RETURN TRUE 
	END IF
	
	DISPLAY "Revisando Posteo de Ventas " TO g_desc	
	SELECT COUNT(*) INTO l_vttcn
	FROM vttcn
	WHERE vttcnftra BETWEEN l_fecha AND t0.gbpmtfdia
	AND   vttcnpost = 0
	IF l_vttcn > 0 THEN  
		 LET g_modulo = "Ventas"
		RETURN TRUE 
	END IF
		
	DISPLAY "Revisando Posteo de Inventarios " TO g_desc	
	SELECT COUNT(*) INTO l_intcn
	FROM intcn
	WHERE intcnftra BETWEEN l_fecha AND t0.gbpmtfdia
	AND   intcnpost = 0
	IF l_intcn > 0 THEN  
		LET g_modulo = "Inventario"
		RETURN TRUE 
	END IF

	DISPLAY "Revisando Posteo de Ctas x Cobrar " TO g_desc	
	SELECT COUNT(*) INTO l_cctcn
	FROM cctcn
	WHERE cctcnftra BETWEEN l_fecha AND t0.gbpmtfdia
	AND   cctcnpost = 0
	IF l_cctcn > 0 THEN  
		LET g_modulo = "Cuentas Corrientes"
		RETURN TRUE 
	END IF
	#inicio (@#)1-A
	DISPLAY "Revisando Posteo de Ctas x Pagar " TO g_desc	
	DISPLAY l_fecha
	DISPLAY t0.gbpmtfdia
	SELECT COUNT(*) INTO l_cptcn
	FROM cptcn
	WHERE cptcnftra BETWEEN l_fecha AND t0.gbpmtfdia
	AND   cptcnpost = 0
	IF l_cptcn > 0 THEN  
		LET g_modulo = "Cuentas por Pagar"
#		DISPLAY "UNO"
#		SLEEP 1
		RETURN TRUE 
	END IF
	#FIN (@#)1-A

	DISPLAY "Revisando Posteo de Compras " TO g_desc	
	SELECT COUNT(*) INTO l_cotcn
	FROM cotcn
	WHERE cotcnftra BETWEEN l_fecha AND t0.gbpmtfdia
	AND   cotcnpost = 0
	IF l_cotcn > 0 THEN  
		LET g_modulo = "Compras"
		RETURN TRUE 
	END IF

	DISPLAY "Revisando Posteo de P. Consumo " TO g_desc	
	SELECT COUNT(*) INTO l_pctcn
	FROM pctcn
	WHERE pctcnftra BETWEEN l_fecha AND t0.gbpmtfdia
	AND   pctcnpost = 0
	IF l_pctcn > 0 THEN  
		LET g_modulo = "Prestamos de Consumo"
		RETURN TRUE 
	END IF

	DISPLAY "Revisando Posteo de Tesoreria " TO g_desc	
	SELECT COUNT(*) INTO l_tstcn
	FROM tstcn
	WHERE tstcnftra BETWEEN l_fecha AND t0.gbpmtfdia
	AND   tstcnpost = 0
	IF l_tstcn > 0 THEN  
		LET g_modulo = "Prestamos de Tesoreria"
		RETURN TRUE 
	END IF

        LET g_modulo = " "
	RETURN FALSE

END FUNCTION

FUNCTION f9800_stritar_gb306() 
	DEFINE l1	RECORD
				ntra	INTEGER,
				ftra	DATE,
				cart	CHAR(15),
				cven	SMALLINT
			END RECORD,
		l_ctap, l_conta SMALLINT,
	       l_fecha  DATE
        DEFINE l_mge,l_tar DECIMAL(14,2)
	
	LET l_fecha = MDY(MONTH(t0.gbpmtfdia),1,YEAR(t0.gbpmtfdia))
	LET l_mge = 0.0

	DISPLAY "Revisando Stock de S.RIMAC" TO g_desc	
        SELECT nvl(SUM(inarastot),0) INTO l_mge
        FROM inara
        WHERE inaracgru = 202
        AND inaracsub =109
        AND inaracalm IN ( SELECT inalmcalm 
                           FROM inalm
                           WHERE inalmplaz = t0.gbpmtplaz)
	IF l_mge > 0 THEN
		LET g_mensaje = "             Stock de S.RIMAC"
		RETURN TRUE
	END IF

	DISPLAY "Revisando Stock de Tarj. Virtual. " TO g_desc	
	#Inicio (@#)6-A
	LET l_tar = 0
	{
	SELECT nvl(SUM(inarastot),0) INTO l_tar
	FROM inara WHERE inaracgru = 100
	AND inaracsub BETWEEN 1 AND 999
	AND inaracalm IN ( SELECT inalmcalm FROM inalm
			WHERE inalmplaz = t0.gbpmtplaz)
			}
	#Fin (@#)6-A
	IF l_tar > 0 THEN
		LET g_mensaje = "        Stock de Tarjeta Virtuales"
		RETURN TRUE
	END IF
#QUITAR DESPUES DEL CIERRE DE MES
{
	DISPLAY "Revisando Stock de CxP - Mercaderia " TO g_desc	
	SELECT COUNT(*) INTO l_ctap
	FROM cpmcp
	WHERE cpmcpmorg = 17
	AND   cpmcpsald > 0
	AND   cpmcpfreg BETWEEN l_fecha AND t0.gbpmtfdia
	AND   cpmcpmrcb <> 9
	AND   cpmcpplaz = t0.gbpmtplaz
	IF l_ctap > 0 THEN
		LET g_mensaje ="Cuentas x Pagar de Recepci¢n de Mercader¡a"	
		DISPLAY "DOS"
		SLEEP 1
		RETURN TRUE
	END IF
}

	##### Revisa si falta ingresar MGEs	
	{DISPLAY "Revisando MGE'S x Ingresar " TO g_desc	
	DECLARE q_curmge CURSOR FOR	
	SELECT vtnvhntra,vtnvhftra,vtnvacart,SUM(vtnvacven)               
	  FROM vtnvh, vtnva
	 WHERE vtnvhftra BETWEEN l_fecha AND t0.gbpmtfdia
           AND vtnvhstat = 0
           AND vtnvhtnve <> 6
	   AND vtnvhntra = vtnvantra           
	   AND vtnvacart IN (SELECT inartcart FROM inart
			      WHERE inartcgru BETWEEN 200 AND 201)
	   AND vtnvhntra NOT IN ( SELECT vtdevnvta FROM vtdev
				   WHERE vtdevnvta = vtnvhntra) 
         GROUP BY 1,2,3
         ORDER BY vtnvhftra

	FOREACH q_curmge INTO l1.*

		SELECT COUNT(*) INTO l_conta
                FROM efser
                WHERE(efsernvta=l1.ntra OR efsernvt1=l1.ntra)
                AND efsercodp=l1.cart
                AND efsermrcb=0

                IF NOT(l_conta >= l1.cven) THEN
			LET g_mensaje =  "MGEs x Ingresar el ",l1.ftra," Ntra. ",l1.ntra USING "<<<<<<"
                        RETURN true
		END IF
	END FOREACH}

        LET g_mensaje =""
	RETURN FALSE

END FUNCTION

FUNCTION f1500_anula_preventa_gb306(l_ntra,l_tipo)
        DEFINE  l_ntra  INTEGER,
                l_tipo  CHAR(1),
                l_cart  CHAR(15),
                l_cven  SMALLINT,
                l_text  CHAR(150),
                #Inicio (@#)4-A
                l_spro	CHAR(500),
                l_resu	INTEGER
                #Fin (@#)4-A
                ,l_count SMALLINT # (@#)11-A
	
        LET g_hora = TIME
        UPDATE vtprv SET vtprvstat = 9
        WHERE vtprvntra = l_ntra
        IF NOT f0500_error_gb000(status,"vtprv") THEN
                ERROR "No se pudo Anular vtprv"
                SLEEP 1
                LET l_text = "no act vtprv plaza:",t0.gbpmtplaz
                #Inicio (@#)4-A
                #INSERT INTO tbsfi:efsss VALUES(l_text)
                {
                 SQL
                	EXECUTE PROCEDURE tbsfi:pa_sfi_gb306_RegistrarSeguimientoCierre($l_text,NULL,NULL) INTO $l_resu
                END SQL
                }
                LET l_spro="EXECUTE PROCEDURE ", f0020_buscar_bd_gb000(0,"F") CLIPPED , ":pa_sfi_gb306_RegistrarSeguimientoCierre('", l_text  CLIPPED ,"',NULL,NULL)"
	        PREPARE p_spro_01 FROM l_spro
	        EXECUTE p_spro_01 INTO l_resu
                #Fin (@#)4-A
                RETURN FALSE
        END IF
        
        # (@#)11-A - inicio
        IF g_flag_hybris = 1 THEN
	        SELECT COUNT(*) 
	        INTO l_count
	        FROM evthbs
	        WHERE evthbsntra = l_ntra
	        AND evthbsagen = t0.gbpmtplaz
	        AND evthbsmrcb = 0
	        
	        IF l_count > 0 THEN
	        	UPDATE evthbs
	        	SET evthbseeha =0,
	        	evthbsesta = 3
	        	WHERE evthbsntra = l_ntra
	        END IF        
      	END IF
        # (@#)11-A - fin
        
        UPDATE vtprd
           SET vtprdstat = 9
         WHERE vtprdntra = l_ntra

        IF l_tipo = "C" THEN
            DECLARE q_cdet CURSOR WITH HOLD FOR
                SELECT vtprdcart,vtprdcven
                FROM vtprd WHERE vtprdntra = l_ntra

            FOREACH q_cdet INTO l_cart,l_cven
                BEGIN WORK
                IF NOT f3100_rev_compromiso_articulo_in000(l_cart,l_cven)
                  THEN
                        ERROR "No se puede Descomprometer STOCK"
                        SLEEP 1
                LET l_text = "no revert compromiso plaza:",t0.gbpmtplaz
                #Inicio (@#)4-A
                #INSERT INTO tbsfi:efsss VALUES(l_text)
                {
                 SQL
                	EXECUTE PROCEDURE tbsfi:pa_sfi_gb306_RegistrarSeguimientoCierre($l_text,NULL,NULL)
                END SQL
                }
                LET l_spro="EXECUTE PROCEDURE ", f0020_buscar_bd_gb000(0,"F") CLIPPED , ":pa_sfi_gb306_RegistrarSeguimientoCierre('", l_text CLIPPED ,"',NULL,NULL)"
	        PREPARE p_spro_02 FROM l_spro
	        EXECUTE p_spro_02 INTO l_resu
                #Fin (@#)4-A
                        ROLLBACK WORK
                        RETURN
                END IF
                COMMIT WORK
            END FOREACH
        ELSE
                UPDATE pcprv
                SET pcprvstat = 9
                WHERE pcprvnvta = l_ntra
                IF NOT f0500_error_gb000(status,"pcprv") THEN
                        ERROR "No se puede anular pcprv"
                        SLEEP 1
                LET l_text = "no act pcprv plaza:",t0.gbpmtplaz
                #Inicio (@#)4-A
                #INSERT INTO tbsfi:efsss VALUES(l_text)
                {
                SQL
                	EXECUTE PROCEDURE tbsfi:pa_sfi_gb306_RegistrarSeguimientoCierre($l_text,NULL,NULL)
                END SQL
                }
                LET l_spro="EXECUTE PROCEDURE ", f0020_buscar_bd_gb000(0,"F") CLIPPED , ":pa_sfi_gb306_RegistrarSeguimientoCierre('", l_text CLIPPED ,"',NULL,NULL)"
	        PREPARE p_spro_03 FROM l_spro
	        EXECUTE p_spro_03 INTO l_resu
	        
                #Fin (@#)4-A
                        RETURN
                END IF
        END IF
END FUNCTION


###################
# RUTINAS GENERALES
###################

FUNCTION f6050_buscar_empresa_gb306()
        INITIALIZE t0.* TO NULL
        SELECT * INTO t0.* FROM gbpmt
	SELECT * INTO t4.* FROM cjctl
				# (@#)11-A - INICIO
				select eefparent1 INTO g_flag_hybris from eefpar where eefparpfij = 216 AND eefpartipo=1 AND eefparcor1=1 AND eefparstat=0				
				# (@#)11-A - FIN		
	SELECT vtautusrn INTO g_admin
        FROM vtaut
        WHERE vtauttipo = "A"
            AND vtautusrn = g_user
END FUNCTION

FUNCTION f6100_cabecera_gb306()
        DEFINE  l_string CHAR(33),
                l_empres CHAR(33),
                l_sistem CHAR(16),
                l_col    SMALLINT

# DISPLAY DEL SISTEMA
        LET     l_string = "GENERAL"
        LET     l_col = ((16 - length(l_string)) / 2)
        LET     l_sistem = " "
        LET     l_sistem[l_col+1,16-l_col] = l_string
        DISPLAY l_sistem AT 4,2

# DISPLAY DEL NOMBRE DE LA EMPRESA
        LET     l_string = t0.gbpmtnomb
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
        DISPLAY l_empres AT 5,24
END FUNCTION

FUNCTION f6300_display_datos_gb306()
        DISPLAY t0.gbpmtfdia TO fdia
        DISPLAY t0.gbpmttcof TO tcof
        DISPLAY t0.gbpmttcco TO tcco
        DISPLAY t0.gbpmttcve TO tcve
	
	DISPLAY t4.cjctltccd TO tccd
	DISPLAY t4.cjctltcvd TO tcvd
END FUNCTION
FUNCTION f0700_vta_anuladas_gb306()
        DEFINE  l_ntra  INTEGER,
                l_nomb  CHAR(35),
                l_nser  CHAR(3),
                l_nfac  INTEGER,
                l_cage  INTEGER,
                x       SMALLINT,
                l_numt  SMALLINT

        INITIALIZE p25[1].* TO NULL
        #FOR i = 2 TO 50
        FOR i = 2 TO 100
            LET p25[i].* = p25[1].*
        END FOR

        SELECT COUNT(*) INTO l_numt
                FROM efavt
                WHERE efavtftra = t0.gbpmtfdia
                AND   efavtplaz = t0.gbpmtplaz

        IF l_numt > 0 THEN
                ERROR "                   CONTROL-C PARA SALIR                  "
                DECLARE q_sindes CURSOR FOR
                SELECT vtnvhntra,vtnvhnser,vtnvhnfac,vtnvhcage,vtnvhnomb
                FROM vtnvh
                WHERE vtnvhftra = t0.gbpmtfdia 
                AND   vtnvhntra in ( 	SELECT efavtntra FROM efavt
                			WHERE efavtftra = t0.gbpmtfdia 
					AND   efavtplaz = t0.gbpmtplaz)
                LET x = 1
                FOREACH q_sindes INTO l_ntra,l_nser,l_nfac,l_cage,l_nomb
                        LET p25[x].ntra = l_ntra
                        LET p25[x].docu = l_nser CLIPPED,"-",l_nfac USING "<<<<<<"
                        LET p25[x].cage = l_cage
                        LET p25[x].nomb = l_nomb
                        LET x = x + 1
                END FOREACH

                OPEN WINDOW w1_gb306x AT 9,12 WITH FORM "gb306x" ATTRIBUTE(FORM LINE 1)
                CALL set_count(x-1)
                DISPLAY ARRAY p25 TO s25.* ATTRIBUTE(REVERSE)
                        ON KEY (CONTROL-C,INTERRUPT)
                        EXIT DISPLAY
                END DISPLAY
                CLOSE WINDOW w1_gb306x
		RETURN TRUE
        END IF
	RETURN FALSE



END FUNCTION

#Inicio (@#)7-A
#VERIFICA SI ES FERIADO
FUNCTION f1600_dia_feriado_gb306(l_fech)
DEFINE 	l_fech  DATE,	#FECHA 
			l_csql	CHAR(600),	#CONSULTA SOBRE FECHA
			l_row SMALLINT     	#CONTADOR   			 
	
	LET l_csql="SELECT COUNT(*)  FROM ",f0020_buscar_bd_gb000(0,"S") CLIPPED,":gbfer WHERE gbferfech='",l_fech,"'"
	PREPARE pr1 FROM l_csql
	EXECUTE pr1 INTO  l_row
	IF l_row >0 THEN	
	ERROR "se grabara el mismo TC para el feriado."	
		RETURN TRUE
	ELSE
		RETURN FALSE
	END IF
END FUNCTION
#Fin (@#)7-A