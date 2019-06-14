###############################################################################
# PROGRAMA: ef233.4gl
# VERSION : 1.0
# OBJETIVO: Inventario Fisico de Incautados - SFI
# FECHA   : 08/03/2008
# AUTOR   : GBT
# COMPILAR: ef233.4gl gb001.4gl
#modificaciones:
# codigo	req/help	usuario		fecha
#  001		951		JAG		12/01/2010
# (@#)1-A	5963	FQC		Fernando Quiroz	03/03/2010	Se agrego filtro de baja del articulo
#modificaciones:
# codigo	req	usuario							fecha
#  001		1404	Cesar Chambergo		05/07/2010
# (@#)1-B		  YSV		Yoel Solis Vasquez 05/07/2010	Se agrego columna con dias de incautaci¢n
# (@#)2-A		  GIAN-SS               02/07/2013              Cambio de la llamada directa a tbase por funcion de la libreria gb000
# (@#)3-A		  HD-92512 Junior Coronel - Siempresoft  19/05/2014              Limpiar descripcion de articulo antes de realizar nueva busqueda
# (@#)4-A  20165  	  Evelyn Ancajima- IDE 			 27/02/2017  		 Mejora de reporte de los incautados totales 
# (@#)4-B  20165  	  Evelyn Ancajima- IDE 			 23/03/2017  		 Validar que el saldo capital sea filtrado por el Cod.BRP                                            
# (@#)5-A  23666  	  Dary Sanchez - SES 			 17/05/2019  		 Implementacion de reporte detallado por transaccion y codigo articulo
###############################################################################                                                                                
DATABASE tbsfi

	DEFINE	p1		RECORD
				  fech	DATE,
				  tipo	SMALLINT, 
				  #(@#)5-A - INICIO
				  deta	CHAR(1), -- Variable opcion detallado
				  form	SMALLINT, -- Variable opcion formato
				  gene	CHAR(1) -- -- Variable generar
				  #(@#)5-A - FIN
				END RECORD,
		
		t1		RECORD
				#(@#)4-A - INICIO
				  {	
				  ntra	INTEGER,
				  ftra	DATE,
				  npre	INTEGER,
				  cage	INTEGER,
				  cart	CHAR(15),
				  mest	SMALLINT,
				  nser	CHAR(35),
				  csub	SMALLINT
				  }
				  	
				  nofi INTEGER,      								     
				  cagp CHAR(4),			                      
				  ntra	INTEGER,                                   
				  npre	INTEGER,                                   
				  cage	INTEGER,                                   
				  ftra	DATE,                                      
				  cbrp CHAR(15),			                     
				  cart	CHAR(15),                                  
				  nser	CHAR(35),		                               
				  mest	SMALLINT,                                  
				  capi DECIMAL(8,2),	             
				  csub	SMALLINT 
				 #(@#)4-A - FIN                
				END RECORD,
				
		#(@#)5-A - INICIO
		t1_d		RECORD
				  nofi INTEGER, -- Codigo de Agencia
				  cagp CHAR(4), -- Descripcion Centro (SAP)
				  ntra	INTEGER, -- Numero de Transaccion
				  npre	INTEGER, -- Numero de Prestamo
				  cage	INTEGER, -- Codigo de Cliente
				  ftra	DATE, -- Fecha de Transaccion
				  cbrp CHAR(15), -- Codigo BRP
				  cart	CHAR(15), -- Codigo de articulo
				  nser	CHAR(35), -- Numero de serie
				  mest	SMALLINT, -- Estado
				  capi DECIMAL(8,2), -- Saldo capital
				  csub	SMALLINT, -- Codigo subtipo de articulos
				  agen CHAR(40), -- Nombre de agencia
				  nombage CHAR(100), -- Nombre de cliente
				  fdes	DATE, -- Fecha de desembolso
				  mdes decimal(14,2), -- Monto de desembolso
				  gtota decimal(14,2), -- Saldo Prestamo
				  stat CHAR(200) -- Estado incautado
				END RECORD,
		g_gbconpfij SMALLINT, # para asignar variable gbconpfij
		#(@#)5-A - FIN
		g_tipo		CHAR(1),

		#(@#)5-A - INICIO
		g_deta		CHAR(1), -- Variable reporte detallado
		g_form		CHAR(1), -- Variable formato reporte
		g_gene		CHAR(1), -- Variable generar
		g_true	SMALLINT, -- Variable true
		
		g_const_0 SMALLINT, -- Constante de valor 0
		g_const_1 SMALLINT, -- Constante de valor 1
		g_const_2 SMALLINT, -- Constante de valor 2
		g_const_3 SMALLINT, -- Constante de valor 3
		g_const_9 SMALLINT, -- Constante de valor 9
		g_const_10 SMALLINT, -- Constante de valor 10
		g_const_12 SMALLINT, -- Constante de valor 12
		g_const_88 SMALLINT, -- Constante de valor 88
		g_const_100 SMALLINT, -- Constante de valor 100
		g_const_101 SMALLINT, -- Constante de valor 101
		g_const_340 SMALLINT, -- Constante de valor 340
		g_const_c CHAR(1), -- Constante de valor 'C'
		g_const_d CHAR(1), -- Constante de valor 'D'
		g_const_s CHAR(1), -- Constante de valor 'S'
		g_const_n CHAR(1), -- Constante de valor 'N'
		#(@#)5-A - FIN

			#################################
        	# variables generales NO BORRAR #
        	#################################
        	t0      	RECORD LIKE gbpmt.*,
        	m1     RECORD
                	o1 	CHAR(1),
                	d1 	CHAR(25),
                	o2 	CHAR(1),
                	d2 	CHAR(25),
                	o3 	CHAR(1),
                	d3 	CHAR(25),
                	o4 	CHAR(1),
                	d4 	CHAR(25)
                       END RECORD,
		i		SMALLINT,
       		g_user          CHAR(3),
        	g_string        CHAR(79),
        	g_ancho         SMALLINT,
		g_opcion	SMALLINT,
        	g_spool         CHAR(10),
        	cart	        CHAR(15)

MAIN 
	IF NOT f0000_open_database_gb000() THEN EXIT PROGRAM END IF
	DEFER INTERRUPT
	OPTIONS PROMPT LINE 22,
                ERROR  LINE 23
	SET LOCK MODE TO WAIT
	#WHENEVER ERROR CONTINUE
        OPEN FORM ef233_01 FROM "ef233a"
        DISPLAY FORM ef233_01
        IF NOT f6050_empresa_ef233() THEN
        	ERROR "No existen parametros"
	    	EXIT PROGRAM
	END IF
        CALL f6100_cabecera_ef233()
        CALL f6200_carga_menu_ef233()
	#(@#)5-A - INICIO
	CALL f100_inicializar_constantes()
	CALL f0251_preparar_cursores_ef233()
	#(@#)5-A - FIN
	CALL f0300_proceso_ef233()
	#(@#)5-A - INICIO
	CALL f0010_libera_cursores_reporte_detallado_ef233()
	#(@#)5-A - FIN
END MAIN

###########################
# DECLARACION DE PUNTEROS #
###########################

#(@#)5-A - INICIO
FUNCTION f0251_preparar_cursores_ef233()
-- Descripción: Funcion que inicializa cursores
	DEFINE
		l_text	CHAR(500),-- Variable asignacion de prepares 1
		l_egbhctcagp CHAR(4), -- Variable centro (SAP)
		l_gbofihos CHAR (30), -- Variable hos de database
		l_gbofidesc CHAR(40),-- Variable Nombre de agencia
		l_gbagenomb CHAR(100),-- Variable Nombre de cliente
		l_pcmpcfdes DATE,-- Variable Fecha de desembolso
		l_pcmpcmdes decimal(14,2),-- Variable Monto de desembolso
		l_pcppgtota decimal(14,2), -- Variable Saldo Prestamo
		l_gbcondesc CHAR(200), -- Variable Estado incautado
		l_sql CHAR(500),--Variable asignacion de prepares 2
		l_sql1 CHAR(500),--Variable asignacion de prepares 3
		l_sql2 CHAR(1000),--Variable asignacion de prepares 4
		l1 RECORD 
			efhtintra LIKE efhti.efhtintra,
			efhtinpre LIKE efhti.efhtinpre,
			efhticage LIKE efhti.efhticage,
			efhtiftra LIKE efhti.efhtiftra,
			efhtiestd LIKE efhti.efhtiestd, 
			efdticorr LIKE efdti.efdticorr,
			efdticart LIKE efdti.efdticart,
			efdtinser LIKE efdti.efdtinser,
			efdtimest LIKE efdti.efdtimest,
			efhticapi LIKE efhti.efhticapi,
			efdticsub LIKE efdti.efdticsub
			
		END RECORD,
		l2 RECORD
			 gbofinofi LIKE gbofi.gbofinofi,
			 gbofihost LIKE gbofi.gbofihost,
			 gboficemp LIKE gbofi.gboficemp
			END RECORD
		
	LET l_sql = " SELECT gbofinofi, gbofihost, gboficemp", 					
					" FROM gbofi "
	IF t0.gbpmtplaz = g_const_88 THEN		
		LET l_sql =l_sql CLIPPED, " WHERE gbofinofi  NOT IN (0,1,88,50,999) "
	ELSE
		LET l_sql =l_sql CLIPPED, " WHERE gbofinofi=", t0.gbpmtplaz
	END IF

	LET l_sql = l_sql CLIPPED," AND gboficemp IN ",
					" (SELECT egbinstcodi FROM EGBINST",
					" WHERE egbinstesta=1",
					" AND EGBINSTRTAL=1)",
					" ORDER BY 1 "
	PREPARE p_sql_00_d FROM l_sql
	DECLARE c_cursor_00_d CURSOR FOR p_sql_00_d

	LET l_sql2 = " SELECT efhtintra,efhtinpre ,efhticage ,efhtiftra, ",
					 " efdticorr,efdticart ,efdtinser , efdtimest , ",
					 " efhticapi,efdticsub, ",
					 " (SELECT gbofidesc ",     
						" FROM gbofi ",
						" where gbofinofi = ? ),", 
					 " (SELECT egbhctcagp ",     
						" FROM '", f0020_buscar_bd_gb000(g_const_0,g_const_s) CLIPPED,"':egbhct ",
               	" where egbhctcags = ? ",
               	" and egbhcttipo = ",g_const_0,
               	" and egbhctmrcb = ",g_const_0,
               	" and egbhctcres = ? ),", 
					 "(select gbofihost from gbofi where gbofinofi = ? )",
					 " FROM '" ,l2.gbofihost CLIPPED,"':efdti,'",l2.gbofihost CLIPPED,"':efhti",
					 " WHERE efdtiftra <= ?",
					 " AND efdtitbaj = ",g_const_0,
					 " AND efhtitdoc = ",g_const_1,
					 " AND efhtimrcb = ",g_const_0,
					 " AND efhtintra = efdtintra ",
					 " AND efhtinpre NOT IN (SELECT efhtinpre ",
					 " FROM tbsfi088:efhti ",
					 " WHERE efhtiserf IS NOT NULL ",
					 " AND   efhticorf IS NOT NULL) ",
					 " AND efhtiestd IN (1,2)"
	PREPARE p_sql_01_d FROM l_sql2
	DECLARE c_cursor_01_d CURSOR FOR p_sql_01_d

	LET g_gbconpfij = g_const_101
	
	LET l_text = 'SELECT gbagenomb',
              '  FROM gbage',
              ' where gbagecage = ? '
   PREPARE p_sql_04_d    FROM l_text
   DECLARE c_cursor_04_d CURSOR FOR p_sql_04_d

	LET l_text = 'SELECT pcmpcfdes,pcmpcmdes',
              '  FROM pcmpc',
              ' where pcmpcnpre = ? '
   PREPARE p_sql_05_d    FROM l_text
   DECLARE c_cursor_05_d CURSOR FOR p_sql_05_d

	LET l_text = 'SELECT pcppgtota',
              '  FROM pcppg',
              ' where pcppgnpre = ? '
   PREPARE p_sql_03_d    FROM l_text
   DECLARE c_cursor_03_d CURSOR FOR p_sql_03_d

	LET l_text = 'SELECT gbcondesc',
              '  FROM gbcon',
              ' where gbconcorr = ? ',
				    ' and gbconpfij = ? '
   PREPARE p_sql_06_d    FROM l_text
   DECLARE c_cursor_06_d CURSOR FOR p_sql_06_d

END FUNCTION
#(@#)5-A - FIN

#(@#)5-A - INICIO
FUNCTION f0010_libera_cursores_reporte_detallado_ef233()
# Descripción: Función que libera los cursores utilizados por el reporte detallado
	FREE c_cursor_00_d
	FREE c_cursor_01_d
	FREE c_cursor_03_d
	FREE c_cursor_04_d
	FREE c_cursor_05_d
	FREE c_cursor_06_d
END FUNCTION
#(@#)5-A - FIN


FUNCTION f0250_declarar_puntero_ef233()
	DEFINE	l_text	CHAR(500), 
#(@#)4-A - INICIO
{	  
		IF p1.tipo = 1 THEN
       		DECLARE q_curs CURSOR FOR
		SELECT efhtintra ,efhtiftra ,efhtinpre ,
			efhticage ,efdticart , efdtimest ,
			efdtinser ,efdticsub
		  FROM efhti,efdti
		 WHERE efdtiftra <= p1.fech
		 	 AND efdtitbaj = 0  #(@#)1-A
		 	 AND efhtitdoc = 1 #(@#)1-A
		   AND efhtimrcb = 0
		   AND efhtintra = efdtintra
		   AND efhtinpre NOT IN (	SELECT efhtinpre 
						FROM tbsfi088:efhti
						WHERE efhtiserf IS NOT NULL
						AND   efhticorf IS NOT NULL)
		   AND efhtiestd IN (1,2) #(@#)1-A
		 ORDER BY 1
	ELSE
                DECLARE q_cur1 CURSOR FOR
                SELECT efhtintra ,efhtiftra ,efhtinpre ,
                        efhticage ,efdticart , efdtimest ,
                        efdtinser ,efdticsub
                  FROM efhti,efdti
                 WHERE efdtiftra <= p1.fech
                 	 AND efdtitbaj = 0 #(@#)1-A
                 	 AND efhtitdoc = 1 #(@#)1-A
                   AND efhtimrcb = 0
                   AND efhtintra = efdtintra
                   AND efhtinpre NOT IN (       SELECT efhtinpre
                                                FROM tbsfi088:efhti
                                                WHERE efhtiserf IS NOT NULL
                                                AND   efhticorf IS NOT NULL)
                   AND efhtiestd IN (1,2) #(@#)1-A
                 ORDER BY 8
	END IF
} 

		l_egbhctcagp CHAR(4),
		l_gbofihos CHAR (30),
		#(@#)5-A - INICIO
		l_gbofidesc CHAR(40),-- Variable Nombre de agencia
		l_gbagenomb CHAR(100),-- Variable Nombre de cliente
		l_pcmpcfdes DATE,-- Variable Fecha de desembolso
		l_pcmpcmdes decimal(14,2),-- Variable Monto de desembolso
		l_pcppgtota decimal(14,2), -- Variable Saldo Prestamo
		l_gbcondesc CHAR(200), -- Variable Estado incautado
		#(@#)5-A - FIN
		l_sql CHAR(500), 	
		l_sql1 CHAR(500),	
		l_sql2 CHAR(1000),			
		l1 RECORD 
			efhtintra LIKE efhti.efhtintra,
			efhtinpre LIKE efhti.efhtinpre,
			efhticage LIKE efhti.efhticage,
			efhtiftra LIKE efhti.efhtiftra,
			#(@#)5-A - INICIO
			efhtiestd LIKE efhti.efhtiestd, -- Campo para estado incautado
			#(@#)5-A - FIN
			efdticorr LIKE efdti.efdticorr,
			efdticart LIKE efdti.efdticart,
			efdtinser LIKE efdti.efdtinser,
			efdtimest LIKE efdti.efdtimest,
			efhticapi LIKE efhti.efhticapi,
			efdticsub LIKE efdti.efdticsub
			
		END RECORD,
		l2 RECORD
			 gbofinofi LIKE gbofi.gbofinofi,
			 gbofihost LIKE gbofi.gbofihost,
			 gboficemp LIKE gbofi.gboficemp
			END RECORD
																
				LET l_sql = " SELECT gbofinofi, gbofihost, gboficemp", 					
					    " FROM gbofi "
				IF t0.gbpmtplaz = 88 THEN		
						LET l_sql =l_sql CLIPPED, " WHERE gbofinofi  NOT IN (0,1,88,50,999) "
				ELSE
						LET l_sql =l_sql CLIPPED, " WHERE gbofinofi=", t0.gbpmtplaz
				END IF
				LET l_sql =l_sql CLIPPED," AND gboficemp IN ",
					"	(SELECT egbinstcodi FROM EGBINST",
					"	WHERE egbinstesta=1",
					"	AND EGBINSTRTAL=1)",
					" ORDER BY 1 "
				
				PREPARE p_sql_00 FROM l_sql
				DECLARE c_cursor_00 CURSOR FOR p_sql_00	

			#(@#)5-A - INICIO
			IF p1.deta = g_const_n THEN
			#(@#)5-A - FIN
			FOREACH c_cursor_00 INTO l2.*	
			
				LET l_sql2 = " SELECT efhtintra,efhtinpre ,efhticage ,efhtiftra, ",
					     " efdticorr,efdticart ,efdtinser , efdtimest , ",
					     " efhticapi,efdticsub, ",
					     " (SELECT egbhctcagp ",     
               				     " FROM ", f0020_buscar_bd_gb000(0,"S") CLIPPED,":egbhct ",
               				     " where egbhctcags = ",l2.gbofinofi, 
               				     " and egbhcttipo = 0 ",
               				     " and egbhctmrcb = 0 ",
               				     " and egbhctcres = ", l2.gboficemp,"),",
               				     "(select gbofihost from gbofi where gbofinofi = ", l2.gbofinofi, ")",
					     " FROM " ,l2.gbofihost CLIPPED,":efdti,",l2.gbofihost CLIPPED,":efhti ",
					     " WHERE efdtiftra <= '",p1.fech,"'",
					     " AND efdtitbaj = 0 ",
					     " AND efhtitdoc = 1 ",
					     " AND efhtimrcb = 0 ",
					     " AND efhtintra = efdtintra ",
					     " AND efhtinpre NOT IN (SELECT efhtinpre ",
					     " FROM tbsfi088:efhti ",
					     " WHERE efhtiserf IS NOT NULL ",
					     " AND   efhticorf IS NOT NULL) ",
					     " AND efhtiestd IN (1,2)"		
				
               			PREPARE p_sql_01 FROM l_sql2
               			DECLARE c_cursor_01 CURSOR FOR p_sql_01	
				FOREACH c_cursor_01 INTO 
				#(@#)5-A - INICIO
				l1.efhtintra,
				l1.efhtinpre,
				l1.efhticage,
				l1.efhtiftra,
				l1.efdticorr,
				l1.efdticart,
				l1.efdtinser,
				l1.efdtimest,
				l1.efhticapi,
				l1.efdticsub,
				l_egbhctcagp,
				l_gbofihos
				#(@#)5-A - FIN
				
				#(@#)4-B - INICIO				
				#LET l1.efhticapi = f5002_calcular_saldo_ef233(l1.efhtinpre, l1.efhticapi, l1.efdticart, l_gbofihos)
				LET l1.efhticapi = f5002_calcular_saldo_ef233(l1.efhtinpre, l1.efhticapi, l1.efdticart, l_gbofihos, l1.efdticorr)
				#(@#)4-B - FIN
				INSERT INTO tmp_01 VALUES
					(
						l2.gbofinofi,
						l_egbhctcagp,
						l1.efhtintra,
						l1.efhtinpre,
						l1.efhticage,
						l1.efhtiftra,
						l1.efdticorr,
						l1.efdticart,
						l1.efdtinser,
						l1.efdtimest,
						l1.efhticapi,
						l1.efdticsub
						)
			 	END FOREACH
			END FOREACH

	#(@#)5-A - INICIO
	ELSE
		OPEN c_cursor_00_d 
		FETCH c_cursor_00_d INTO l2.gbofinofi,l2.gbofihost,l2.gboficemp
		WHILE STATUS <> NOTFOUND
		
			OPEN c_cursor_01_d USING l2.gbofinofi,l2.gbofinofi,l2.gboficemp,l2.gbofinofi,p1.fech
			FETCH c_cursor_01_d INTO l1.efhtintra,l1.efhtinpre,l1.efhticage,l1.efhtiftra,
											 l1.efdticorr,l1.efdticart,l1.efdtinser,l1.efdtimest,
											 l1.efhticapi,l1.efdticsub,l_gbofidesc,l_egbhctcagp,
											 l_gbofihos
			WHILE STATUS <> NOTFOUND
	
	
				OPEN c_cursor_04_d USING l1.efhticage
				FETCH c_cursor_04_d INTO l_gbagenomb
				
				OPEN c_cursor_05_d USING l1.efhtinpre
				FETCH c_cursor_05_d INTO l_pcmpcfdes,l_pcmpcmdes
			
				OPEN c_cursor_03_d USING l1.efhtinpre
				FETCH c_cursor_03_d INTO l_pcppgtota
				
				OPEN c_cursor_06_d USING l1.efhtiestd,g_gbconpfij
				FETCH c_cursor_06_d INTO l_gbcondesc

				LET l1.efhticapi = f5002_calcular_saldo_ef233(l1.efhtinpre, l1.efhticapi, l1.efdticart, l_gbofihos, l1.efdticorr)

				INSERT INTO tmp_01_d VALUES
					(
					l2.gbofinofi,l_egbhctcagp,l1.efhtintra,l1.efhtinpre,l1.efhticage,l1.efhtiftra,
					l1.efdticorr,l1.efdticart,l1.efdtinser,l1.efdtimest,l1.efhticapi,l1.efdticsub,
					l_gbofidesc,l_gbagenomb,l_pcmpcfdes,l_pcmpcmdes,l_pcppgtota,l_gbcondesc
					)
		FETCH c_cursor_01_d INTO l1.efhtintra,l1.efhtinpre,l1.efhticage,l1.efhtiftra,
										 l1.efdticorr,l1.efdticart,l1.efdtinser,l1.efdtimest,
										 l1.efhticapi,l1.efdticsub,l_gbofidesc,l_egbhctcagp,
										 l_gbofihos
		END WHILE
		CLOSE c_cursor_01_d
		
	FETCH c_cursor_00_d INTO l2.gbofinofi,l2.gbofihost,l2.gboficemp
	END WHILE
	CLOSE c_cursor_00_d
	END IF
	#(@#)5-A - FIN

	IF p1.tipo = 1 THEN
	#(@#)5-A - INICIO
		IF p1.deta = g_const_n THEN
	#(@#)5-A - FIN
			DECLARE q_curs_ord1 CURSOR FOR 
				SELECT gbofinofi,egbhctcagp,efhtintra,efhtinpre,efhticage,efhtiftra,efdticorr,
						 efdticart,efdtinser,efdtimest,efhticapi,efdticsub
				FROM tmp_01 
				ORDER BY 1,3
		#(@#)5-A - INICIO
		ELSE
			DECLARE q_curs_ord1_d CURSOR FOR 
			SELECT gbofinofi,egbhctcagp,efhtintra,efhtinpre,efhticage,efhtiftra,efdticorr,
					 efdticart,efdtinser,efdtimest,efhticapi,efdticsub,gbofidesc,gbagenomb,
					 pcmpcfdes,pcmpcmdes,pcppgtota,gbcondesc
			FROM tmp_01_d 
			ORDER BY gbofinofi,efhtintra
		END IF
		#(@#)5-A - FIN
	ELSE
		#(@#)5-A - INICIO
		IF p1.deta = g_const_n THEN
		#(@#)5-A - FIN
			DECLARE q_curs_ord2 CURSOR FOR 
				SELECT 
					gbofinofi,egbhctcagp,efhtintra,efhtinpre,efhticage,efhtiftra,efdticorr,
					efdticart,efdtinser,efdtimest,efhticapi,efdticsub 
				FROM tmp_01 
				ORDER BY 1,12
		#(@#)5-A - INICIO
			ELSE
			DECLARE q_curs_ord2_d CURSOR FOR 
				SELECT 
					gbofinofi,egbhctcagp,efhtintra,efhtinpre,efhticage,efhtiftra,efdticorr,
					efdticart,efdtinser,efdtimest,efhticapi,efdticsub,gbofidesc,gbagenomb,
					pcmpcfdes,pcmpcmdes,pcppgtota,gbcondesc
				FROM tmp_01_d
				ORDER BY gbofinofi,efdticsub
		END IF
		#(@#)5-A - FIN
	END IF 	
#(@#)4-A - FIN
END FUNCTION

#(@#)5-A - INICIO
FUNCTION f100_inicializar_constantes()
# Descripción: Inicializa contantes
	LET g_const_0 = 0
	LET g_const_1 = 1
	LET g_const_2 = 2
	LET g_const_3 = 3
	LET g_const_9 = 9
	LET g_const_10 = 10
	LET g_const_12 = 12
	LET g_const_100 = 100
	LET g_const_88 = 88
	LET g_const_101 = 101
	LET g_const_340 = 340
	LET g_const_c = 'C'
	LET g_const_d = 'D'
	LET g_const_s = 'S'
	LET g_const_n = 'N'
END FUNCTION
#(@#)5-A - FIN

#(@#)4-A - INICIO
FUNCTION f2295_temporal_ef233(l_flag)								
	DEFINE l_flag CHAR(1)
	
	SQL
	DROP TABLE IF EXISTS tmp_01;
	END SQL

	
	IF l_flag='C' THEN
		
		CREATE TEMP TABLE tmp_01
		(	gbofinofi INTEGER,
			egbhctcagp CHAR(4),
			efhtintra INTEGER,
		 	efhtinpre INTEGER,
		 	efhticage INTEGER,
		 	efhtiftra DATE,
		 	efdticorr CHAR(15),
		 	efdticart CHAR(15),
		 	efdtinser CHAR(20),
		 	efdtimest SMALLINT,
		 	efhticapi DECIMAL (8,2),
		 	efdticsub SMALLINT
		 )
		WITH NO LOG;
		
	END IF 
END FUNCTION
#(@#)4-A - FIN

#(@#)5-A - INICIO
FUNCTION f2295_temporal_2_ef233(l_flag)
# Descripción:Crea tabla temporal tmp_01_d  

DEFINE l_flag CHAR(1) -- Parametro tabla temporal
      ,l_sql CHAR(500) -- Cadena de Query
		
	CASE l_flag
		WHEN g_const_c
			SQL
			DROP TABLE IF EXISTS tmp_01_d;
			END SQL
 
				LET l_sql = " SELECT gbofinofi ,", -- Campo numero de agencia
										 "egbhctcagp ,", -- Campo descripcion centro (SAP)
										 "efhtintra ,", -- Campo numero de transaccion 
										 "efhtinpre ,", -- Campo numero de prestamo
										 "efhticage ,", -- Campo numero de cliente
										 "efhtiftra ,", -- Campo fecha de transaccion
										 "efdticorr ,", -- Campo codigo BRP
										 "efdticart ,", -- Campo codigo de articulo
										 "efdtinser ,", -- Campo numero de serie
										 "efdtimest ,", --  Campo estado 
										 "efhticapi ,", -- Campo saldo capital
										 "efdticsub ,", -- Campo codigo subtipo de articulo
										 "gbofidesc ,", -- Nombre agencia
										 "gbagenomb ,", -- Nombre cliente
										 "pcmpcfdes ,", -- Fecha desembolso
										 "pcmpcmdes ,", -- Monto desembolso
										 "pcppgtota ,", -- Saldo prestamo
										 "gbcondesc ", -- Estado incautado
								" FROM gbofi,tbase:egbhct,efhti,efdti,gbage,pcmpc,pcppg,gbcon WHERE ",g_const_1, " = ", g_const_0, 
								" INTO TEMP tmp_01_d WITH NO LOG"
				PREPARE s_tmp_01_d FROM l_sql
				EXECUTE s_tmp_01_d
	END CASE
END FUNCTION
#(@#)5-A - FIN
		
###################
# PROCESO CENTRAL #
###################

FUNCTION f0300_proceso_ef233()
	OPTIONS INPUT WRAP
        LET g_spool = "ef233.r"
        WHILE TRUE
        	CALL f6000_limpiar_campos_ef233()
         	INPUT BY NAME m1.* WITHOUT DEFAULTS
                	ON KEY (CONTROL-M)
                       		IF INFIELD(o1) THEN
                       				CALL f2295_temporal_ef233('C')			#(@#)4-A
											#(@#)5-A - INICIO
											CALL f2295_temporal_2_ef233(g_const_c)
											#(@#)5-A - FIN
                        	    IF f0400_pedir_datos_ef233() THEN
				#(@#)5-A - INICIO
				IF p1.deta = g_const_n THEN
				#(@#)5-A - FIN
					IF p1.tipo = 1 THEN
						#(@#)5-A - INICIO
						IF p1.form = g_const_1 THEN
							LET g_spool = "ef233.txt"
							CALL f3000_detalle_ef233() #imprime ordenado por ntra
						ELSE
							LET g_spool = "ef233.xls"
							CALL f2100_detalle_excel_ef233()
						END IF
						#(@#)5-A - FIN
					ELSE
						#(@#)5-A - INICIO
						IF p1.form = g_const_1 THEN
							LET g_spool = "ef233.txt"
						#(@#)5-A - FIN
							CALL f4000_detalle_subg_ef233() #imprime ordenado por csub
						#(@#)5-A - INICIO
						ELSE
							LET g_spool = "ef233.xls"
							CALL f2100_detalle_excel_ef233()
						END IF
						#(@#)5-A - FIN
					END IF
				#(@#)5-A - INICIO
				ELSE
					IF p1.tipo = g_const_1 THEN
						IF p1.form = g_const_1 THEN
							LET g_spool = "ef233.txt"
							CALL f3000_detalle_ef233() #imprime ordenado por ntra
						ELSE
							LET g_spool = "ef233.xls"
							#CALL f4000_detalle_subg_ef233() #imprime ordenado por csub
							CALL f2100_detalle_excel_ef233()
						END IF
					ELSE
						IF p1.form = g_const_1 THEN
						LET g_spool = "ef233.txt"
							CALL f4000_detalle_subg_ef233() #imprime ordenado por csub
						ELSE
						LET g_spool = "ef233.xls"
							CALL f2100_detalle_excel_ef233()
						END IF
					END IF
				END IF
				#(@#)5-A - FIN
                             		CALL f0100_imprimir_gb001(g_spool)
                          	    END IF
                          	    CALL f2295_temporal_ef233('D')				#(@#)4-A
										 #(@#)5-A - INICIO
										 CALL f2295_temporal_2_ef233(g_const_d)
                         	    #(@#)5-A - FIN
										 NEXT FIELD o1   
                       		END IF
                       		IF INFIELD(o2) THEN
                          	    NEXT FIELD o2   
                       		END IF
                       		IF INFIELD(o3) THEN
                          	    CALL f0100_imprimir_gb001(g_spool)
                          	    NEXT FIELD o3   
                       		END IF
                       		IF INFIELD(o4) THEN
                          	    EXIT WHILE
                       		END IF
   	            	BEFORE FIELD o1
                           	DISPLAY m1.d1 TO d1 ATTRIBUTE(REVERSE)
                           	LET m1.o1 = "*"
                    	AFTER FIELD o1
                          	INITIALIZE m1.o1 TO NULL
                          	DISPLAY m1.d1 TO d1 ATTRIBUTE(NORMAL)
                          	DISPLAY m1.o1 TO o1
                    	BEFORE FIELD o2
                           	DISPLAY m1.d2 TO d2 ATTRIBUTE(REVERSE)
                           	LET m1.o2 ="*"
                    	AFTER FIELD o2
                          	INITIALIZE m1.o2 TO NULL
                          	DISPLAY m1.d2 TO d2 ATTRIBUTE(NORMAL)
                          	DISPLAY m1.o2 TO o2
                    	BEFORE FIELD o3
                           	DISPLAY m1.d3 TO d3 ATTRIBUTE(REVERSE)
                           	LET m1.o3 = "*"
                    		AFTER FIELD o3
                          	INITIALIZE m1.o3 TO NULL
                          	DISPLAY m1.d3 TO d3 ATTRIBUTE(NORMAL)
                          	DISPLAY m1.o3 TO o3
                    	BEFORE FIELD o4
                           	DISPLAY m1.d4 TO d4 ATTRIBUTE(REVERSE)
                           	LET m1.o4 = "*"
                    	AFTER FIELD o4
                          	INITIALIZE m1.o4 TO NULL
                          	DISPLAY m1.d4 TO d4 ATTRIBUTE(NORMAL)
                          	DISPLAY m1.o4 TO o4
        	END INPUT
              	IF int_flag THEN
                 	LET int_flag = FALSE
                 	CONTINUE WHILE
              	END IF
	END WHILE
END FUNCTION

FUNCTION f0400_pedir_datos_ef233()
        OPTIONS INPUT NO WRAP
        INPUT BY NAME p1.* WITHOUT DEFAULTS
        	ON KEY (INTERRUPT,CONTROL-C)
                 	LET int_flag = TRUE
                 	EXIT INPUT
		AFTER FIELD fech
			IF p1.fech IS NULL THEN
				LET p1.fech = t0.gbpmtfdia
				DISPLAY BY NAME p1.fech
			END IF
		AFTER FIELD tipo
			IF p1.tipo IS NULL THEN
				ERROR "Ingrese Orden de reporte a Imprimir"
				NEXT FIELD tipo
			END IF
			
			#(@#)5-A - INICIO
			AFTER FIELD deta
			IF p1.deta IS NULL THEN
				ERROR "Ingrese si desea el reporte con detalle o no"
				NEXT FIELD deta
			END IF
			
			AFTER FIELD form
			IF p1.form IS NULL THEN
				ERROR "Ingrese el formato de salida del reporte"
				NEXT FIELD form
			END IF
			
			AFTER FIELD gene
			IF p1.gene IS NULL THEN
				ERROR "Ingrese 'S' para generar"
				NEXT FIELD gene
			END IF
			#(@#)5-A - FIN
			
     	END INPUT
        OPTIONS INPUT WRAP
        IF int_flag THEN
           	LET int_flag = FALSE
           	RETURN FALSE
        END IF
        CALL f0250_declarar_puntero_ef233()
	MESSAGE "Procesando... un momento por favor!!!"
        RETURN TRUE
END FUNCTION

###################
# LISTADO IMPRESO #
###################

FUNCTION f3000_detalle_ef233()
			#(@#)5-A - INICIO
		  IF p1.deta = g_const_n THEN
		  #(@#)5-A - FIN
        START REPORT f3100_detalle_impr_ef233 TO g_spool
		  #(@#)4-A - INICIO
		  #FOREACH q_curs INTO t1.*
        FOREACH q_curs_ord1 INTO t1.*
        #(@#)4-A - FIN
		  		if f3010_busca_traspaso_ef233(t1.npre,t1.cart,t1.nser) then 
					continue foreach
				else
		  			DISPLAY t1.cart TO cart
					OUTPUT TO REPORT f3100_detalle_impr_ef233(t1.*)
				end if
        END FOREACH
		  FINISH REPORT f3100_detalle_impr_ef233
		  #(@#)5-A - INICIO
		  ELSE
		  START REPORT f3101_detalle_impr_d_ef233 TO g_spool
		  FOREACH q_curs_ord1_d INTO t1_d.*
		  		if f3010_busca_traspaso_ef233(t1_d.npre,t1_d.cart,t1_d.nser) then 
					continue foreach
				else
		  			DISPLAY t1_d.cart TO cart
					OUTPUT TO REPORT f3101_detalle_impr_d_ef233(t1_d.*)
				end if
        END FOREACH
		  FINISH REPORT f3101_detalle_impr_d_ef233
		  END IF
		  #(@#)5-A - FIN
END FUNCTION

REPORT f3100_detalle_impr_ef233(r)
	#(@#)4-A - INICIO
     	{
     	DEFINE	r		RECORD
				  ntra	INTEGER,
				  ftra	DATE,
				  npre	INTEGER,
				  cage	INTEGER,
				  cart	CHAR(15),
				  mest	SMALLINT,
				  nser	CHAR(35), 
				  csub	SMALLINT
				END RECORD,
	}
				
	
	DEFINE	r		RECORD
				  nofi 	INTEGER,			
				  cagp 	CHAR(4),			
	 			  ntra	INTEGER,
	  			  npre	INTEGER,
	  			  cage	INTEGER,
	  			  ftra	DATE,
	  			  cbrp CHAR(15),			
	  			  cart	CHAR(15),
	  			  nser	CHAR(35),
	  			  mest	SMALLINT,
	  			  capi DECIMAL(8,2),  			
	  			  csub	SMALLINT
				END RECORD,
				
	#(@#)4-A - FIN
		l_desc	CHAR(30),
		#INICIO(@#)2-A
		l_sql1  CHAR(500)
		#FIN(@#)2-A
		OUTPUT
        	LEFT MARGIN 0
                TOP  MARGIN 0
               	BOTTOM MARGIN 4
               	PAGE LENGTH 66
               	ORDER EXTERNAL BY r.ntra
    	FORMAT
     		PAGE HEADER 
     		#(@#)4-A - INCIO
     		#LET g_ancho  = 142
             	LET g_ancho  = 220
             	#(@#)4-A - FIN				
             	LET g_string = t0.gbpmtnemp CLIPPED
             	PRINT ASCII 15
             	PRINT COLUMN  1,"MODULO EFECTIVA",
                      COLUMN ((g_ancho-length(g_string))/2),g_string CLIPPED,
                      COLUMN (g_ancho-9),"PAG: ",PAGENO USING "<<<<"
             	LET g_string = "Inventario de Bienes en Dacion en Pago" CLIPPED
             	PRINT COLUMN  1,TIME CLIPPED,
                      COLUMN ((g_ancho-length(g_string))/2),g_string CLIPPED,
                      COLUMN (g_ancho-9),TODAY USING "dd-mm-yyyy"
		LET g_string = "Al ", p1.fech USING "dd/mm/yyyy"
             	PRINT COLUMN  1,"ef233.4gl",
                      COLUMN ((g_ancho-length(g_string))/2),g_string CLIPPED
		SKIP 1 LINE
	     	FOR i=1 TO g_ancho-1 PRINT "-"; END FOR PRINT "-"
	  #(@#)4-A - INICIO 
          {		
             	PRINT COLUMN   1,"Trans",
             	      COLUMN   7,"Prestamo",
             	      COLUMN  18,"Cliente",
		      COLUMN  28,"F.Ingreso",
             	      COLUMN  40,"Articulo",
             	      COLUMN  57,"Descripcion",
		      COLUMN  90,"Serie",
		      COLUMN  110,"Estado",
		      COLUMN  121,"F.Registro",
		      COLUMN  133,"Dias BDP"
	  }	      
		      
		PRINT	COLUMN  1,"Agencia",				
             		COLUMN  11,"Centro(SAP)",			
             		COLUMN  25,"Trans",
             	  	COLUMN  32,"Prestamo",
             	  	COLUMN  43,"Cliente",
			COLUMN  54,"F.Ingreso",
			COLUMN  66,"Cod. BRP",
             	  	COLUMN  81,"Articulo",
             	  	COLUMN  98,"Descripcion",
			COLUMN 131,"Serie",
			COLUMN 161,"Estado",
			COLUMN 183,"F.Registro",
			COLUMN 195,"Saldo capital",			
			COLUMN 210,"Dias BDP"				
	#(@#)4-A - FIN
	     	FOR i=1 TO g_ancho-1 PRINT "-"; END FOR PRINT "-"
	BEFORE GROUP OF r.ntra
		#(@#)4-A - INICIO 
		{  
		PRINT COLUMN 1,r.ntra USING "<<<<<",
		      COLUMN 7,r.npre USING "<<<<<<<<<",
		      COLUMN 18,r.cage USING "<<<<<<<<",
		      COLUMN 28,r.ftra USING "dd/mm/yyyy";
		}				
		
		PRINT COLUMN  1,r.nofi USING "<<<<",			
		      COLUMN  11,r.cagp CLIPPED, 									
		      COLUMN  25,r.ntra USING "<<<<<<",
		      COLUMN  32,r.npre USING "<<<<<<<<<",
		      COLUMN  43,r.cage USING "<<<<<<<<",
		      COLUMN  54,r.ftra USING "dd/mm/yyyy";   												
		#(@#)4-A - FIN
   	ON EVERY ROW	
	 #INICIO(@#)2-A
		{SELECT inartdesc	INTO l_desc
		FROM tbase:inart
		WHERE inartcart = r.cart}
		LET l_desc="" # (@#)3-A			
		LET l_sql1="SELECT inartdesc ",
		           " FROM ", f0020_buscar_bd_gb000(0,"S") CLIPPED,":inart",
		           " WHERE inartcart ='", r.cart,"'"
		           PREPARE s_inart FROM l_sql1
			   EXECUTE s_inart INTO l_desc
	#FIN(@#)2-A
		
		#(@#)4-A - INICIO 			
		{		
           	PRINT COLUMN  40,r.cart	CLIPPED,
           	      COLUMN  57,l_desc	CLIPPED,
		      COLUMN  90,r.nser		CLIPPED,
		      COLUMN 110,f5050_busca_estado_ef233(r.mest)
						CLIPPED,
		      COLUMN 122,r.ftra		USING "dd/mm/yyyy",
		      COLUMN 132,f5002_calcular_tiempo_ef233(r.ftra) #(@#)1-B
		}				      
		     
		PRINT 
		      COLUMN  66,r.cbrp CLIPPED,	
		      COLUMN  81,r.cart	CLIPPED,
           	      COLUMN  98,l_desc	CLIPPED,
		      COLUMN 131,r.nser	CLIPPED,
		      COLUMN 161,f5050_busca_estado_ef233(r.mest) CLIPPED,
		      COLUMN 183,r.ftra	USING "dd/mm/yyyy",
		      COLUMN 195,r.capi,							 
		      COLUMN 210,f5002_calcular_tiempo_ef233(r.ftra) #(@#)1-B
		 #(@#)4-A - FIN
        PAGE TRAILER
             	PRINT ASCII 18
    	
END REPORT

#(@#)5-A - INICIO
REPORT f3101_detalle_impr_d_ef233(r_d)
	DEFINE	
				r_d		RECORD
				  nofi 	INTEGER, -- Codigo de Agencia
				  cagp 	CHAR(4), -- Descripcion Centro (SAP)
				  ntra	INTEGER, -- Numero de Transaccion
				  npre	INTEGER, -- Numero de Prestamo
				  cage	INTEGER, -- Codigo de Cliente
				  ftra	DATE, -- Fecha de Transaccion
				  cbrp CHAR(15), -- Codigo BRP
				  cart	CHAR(15), -- Codigo de articulo
				  nser	CHAR(35), -- Numero de serie
				  mest	SMALLINT, -- Estado
				  capi DECIMAL(8,2), -- Saldo capital
				  csub	SMALLINT, -- Codigo subtipo de articulos
				  agen CHAR(40), -- Nombre de agencia
				  nombage CHAR(100), -- Nombre de cliente
				  fdes	DATE, -- Fecha de desembolso
				  mdes decimal(14,2), -- Monto de desembolso
				  gtota decimal(14,2), -- Saldo Prestamo
				  stat CHAR(200) -- Estado incautado
				END RECORD,
			l_desc	CHAR(30), -- Descripcion de articulo
			l_sql1  CHAR(500)  -- Variable de sentencia 
		OUTPUT
        	LEFT MARGIN 0
                TOP  MARGIN 0
               	BOTTOM MARGIN 4
               	PAGE LENGTH 66
               	ORDER EXTERNAL BY r_d.ntra
    	FORMAT
     		PAGE HEADER 
             	LET g_ancho  = g_const_340
             	LET g_string = t0.gbpmtnemp CLIPPED
             	PRINT ASCII 15
             	PRINT COLUMN  1,"MODULO EFECTIVA",
                      COLUMN ((g_ancho-length(g_string))/g_const_2),g_string CLIPPED,
                      COLUMN (g_ancho-g_const_9),"PAG: ",PAGENO USING "<<<<"
             	LET g_string = "Inventario de Bienes en Dacion en Pago" CLIPPED
             	PRINT COLUMN  1,TIME CLIPPED,
                      COLUMN ((g_ancho-length(g_string))/g_const_2),g_string CLIPPED,
                      COLUMN (g_ancho-g_const_9),TODAY USING "dd-mm-yyyy"
		LET g_string = "Al ", p1.fech USING "dd/mm/yyyy"
             	PRINT COLUMN  1,"ef233.4gl",
                      COLUMN ((g_ancho-length(g_string))/g_const_2),g_string CLIPPED
		SKIP 1 LINE
	     	FOR i=1 TO g_ancho - g_const_1 PRINT "-"; END FOR PRINT "-"
	  
		PRINT COLUMN	COLUMN  1,"Agencia",				
							COLUMN  12,"Centro(SAP)",				
							COLUMN  27,"Trans",			
							COLUMN  36,"Prestamo",
							COLUMN  48,"Cliente",
							COLUMN  59,"F.Ingreso",
							COLUMN  72,"Cod. BRP",
							COLUMN  84,"Articulo",
							COLUMN  100,"Descripcion",
							COLUMN  135,"Serie",
							COLUMN  158,"Estado",
							COLUMN 170,"F.Registro",
							COLUMN 185,"Saldo capital",
							COLUMN 201,"Dias BDP",
							COLUMN 211,"Nombre Oficina",			
							COLUMN 227,"Nombre Cliente",
							COLUMN 254,"Fech Desembolso",
							COLUMN 271,"Monto Desembolso",				
							COLUMN 288,"Saldo Prestamo",
							COLUMN 314,"Estado Incautado"
	     	FOR i = g_const_1 TO g_ancho-g_const_1 PRINT "-"; END FOR PRINT "-"
	BEFORE GROUP OF r_d.ntra
		
		PRINT 
				COLUMN  3,r_d.nofi USING "<<<<",			
		      COLUMN  12,r_d.cagp CLIPPED, 									
		      COLUMN  27,r_d.ntra USING "<<<<<<<<<<",
		      COLUMN  36,r_d.npre USING "<<<<<<<<<",
		      COLUMN  48,r_d.cage USING "<<<<<<<<",
		      COLUMN  59,r_d.ftra USING "dd/mm/yyyy"; 
   	ON EVERY ROW	
			LET l_desc=""
			
			LET l_sql1="SELECT inartdesc ",
		             " FROM ", f0020_buscar_bd_gb000(g_const_0,g_const_s) CLIPPED,":inart",
		             " WHERE inartcart ='", r_d.cart,"'"
			PREPARE s_inart_d FROM l_sql1
			EXECUTE s_inart_d INTO l_desc
	
		PRINT 
		      COLUMN 72,r_d.cbrp CLIPPED,	
		      COLUMN 84,r_d.cart	CLIPPED,
           	COLUMN 100,l_desc	CLIPPED,
		      COLUMN 135,r_d.nser	CLIPPED,
		      COLUMN 158,f5050_busca_estado_ef233(r_d.mest) CLIPPED,
		      COLUMN 170,r_d.ftra	USING "dd/mm/yyyy",
		      COLUMN 185,r_d.capi,							 
				COLUMN 201,f5002_calcular_tiempo_ef233(r_d.ftra),
				COLUMN 213,r_d.agen CLIPPED,
				COLUMN 225,r_d.nombage CLIPPED,
				COLUMN 258, r_d.fdes USING "dd/mm/yyyy" CLIPPED,
				COLUMN 277, r_d.mdes USING "<<<<<<<<",
				COLUMN 293,r_d.gtota USING "<<<<<<<<",
				COLUMN 305,r_d.stat CLIPPED
        PAGE TRAILER
            	PRINT ASCII 18
END REPORT
#(@#)5-A - FIN


function f3010_busca_traspaso_ef233(f_npre, f_cart,f_nser)
	define	f_npre	integer,
				f_cart	char(15),
				f_nser	char(35),
				l_tbaj	smallint			
				
	select efdtitbaj into l_tbaj
	from tbsfi088:efhti, tbsfi088:efdti
	where efdtintra = efhtintra 
	and efhtinpre = f_npre
	and efdticart = f_cart
	and efdtinser = f_nser
	AND efhtimrcb = 0 # 001
	AND efdtimrcb = 0 # 001
	if status = notfound then
		let l_tbaj = 0
	end if
	
	if l_tbaj = 0 then
		return false
	end if
	return true
end function


FUNCTION f4000_detalle_subg_ef233()
			#(@#)5-A - INICIO
		  IF p1.deta = g_const_n THEN
		  #(@#)5-A - FIN
        START REPORT f4100_detalle_impr_ef233 TO g_spool
        #(@#)4-A - INCIO	
        #FOREACH q_cur1 INTO t1.*
        FOREACH q_curs_ord2 INTO t1.*
        #(@#)4-A - FIN						
		  		if f3010_busca_traspaso_ef233(t1.npre,t1.cart,t1.nser) then 
					continue foreach
				else
                DISPLAY t1.cart TO cart
                OUTPUT TO REPORT f4100_detalle_impr_ef233(t1.*)
				end if
        END FOREACH
        FINISH REPORT f4100_detalle_impr_ef233
		  #(@#)5-A - INICIO
		  ELSE
		  START REPORT f4101_detalle_impr_d_ef233 TO g_spool
        FOREACH q_curs_ord2_d INTO t1_d.*
		  		if f3010_busca_traspaso_ef233(t1_d.npre,t1_d.cart,t1_d.nser) then 
					continue foreach
				else
                DISPLAY t1_d.cart TO cart
                OUTPUT TO REPORT f4101_detalle_impr_d_ef233(t1_d.*)
				end if
        END FOREACH
        FINISH REPORT f4101_detalle_impr_d_ef233
		  END IF
		  #(@#)5-A - FIN
END FUNCTION

REPORT f4100_detalle_impr_ef233(r)
        DEFINE  r               RECORD
        			#(@#)4-A - INICIO
                                  {
                                  ntra  INTEGER,
                                  ftra  DATE, 
                                  npre  INTEGER,
                                  cage  INTEGER,
                                  cart  CHAR(15),
                                  mest  SMALLINT,
                                  nser  CHAR(35),
                                  csub  SMALLINT
                                  }
                                  
                                nofi 	INTEGER,			   
     				cagp 	CHAR(4),			  
				ntra	INTEGER,                  
				npre	INTEGER,                  
				cage	INTEGER,                  
				ftra	DATE,                     
				cbrp 	CHAR(15),			
				cart	CHAR(15),                 
				nser	CHAR(35),                 
				mest	SMALLINT,                 
				capi 	DECIMAL(8,2),  			  
				csub	SMALLINT  
				#(@#)4-A - FIN             
                                END RECORD,
                l_desc  	CHAR(30),
		l_cont		SMALLINT,
		#INICIO(@#)2-A
		l_sql1          CHAR(100)
		#FIN(@#)2-A
		
        OUTPUT
                LEFT MARGIN 0
                TOP  MARGIN 0
                BOTTOM MARGIN 4
                PAGE LENGTH 66
                ORDER EXTERNAL BY r.csub
        FORMAT
                PAGE HEADER
                #(@#)4-A - INCIO
     		#LET g_ancho  = 142
             	LET g_ancho  = 220
             	#(@#)4-A - FIN
                LET g_string = t0.gbpmtnemp CLIPPED
                PRINT ASCII 15
                PRINT COLUMN  1,"MODULO EFECTIVA",
                      COLUMN ((g_ancho-length(g_string))/2),g_string CLIPPED,
                      COLUMN (g_ancho-9),"PAG: ",PAGENO USING "<<<<"
                LET g_string = "Inventario de Bienes en Dacion en Pago" CLIPPED
                PRINT COLUMN  1,TIME CLIPPED,
                      COLUMN ((g_ancho-length(g_string))/2),g_string CLIPPED,
                      COLUMN (g_ancho-9),TODAY USING "dd-mm-yyyy"
                LET g_string = "Al ", p1.fech USING "dd/mm/yyyy"
                PRINT COLUMN  1,"ef233.4gl",
                      COLUMN ((g_ancho-length(g_string))/2),g_string CLIPPED
                SKIP 1 LINE
                FOR i=1 TO g_ancho-1 PRINT "-"; END FOR PRINT "-"
                #(@#)4-A - INICIO
                {   
                PRINT COLUMN   1,"Trans",
                      COLUMN   7,"Prestamo",
                      COLUMN  18,"Cliente",
                      COLUMN  28,"F.Ingreso",
                      COLUMN  40,"Articulo",
                      COLUMN  57,"Descripcion",
                      COLUMN  90,"Serie",
                      COLUMN  110,"Estado",
                      COLUMN  121,"F.Registro",
                      COLUMN  133,"Dias BDP"
                }		
                
                PRINT 	COLUMN  1,"Agencia",							
             		COLUMN  11,"Centro(SAP)",					
             		COLUMN  25,"Trans",
             	      	COLUMN  32,"Prestamo",
             	      	COLUMN  43,"Cliente",
		      	COLUMN  54,"F.Ingreso",
		      	COLUMN  66,"Cod. BRP",
             	      	COLUMN  81,"Articulo",
             	      	COLUMN  98,"Descripcion",
		     	COLUMN 131,"Serie",
		     	COLUMN 161,"Estado",
		     	COLUMN 183,"F.Registro",
		     	COLUMN 195,"Saldo capital",			
		     	COLUMN 210,"Dias BDP"						
		 #(@#)4-A - FIN
		     				
                FOR i=1 TO g_ancho-1 PRINT "-"; END FOR PRINT "-"
        BEFORE GROUP OF r.csub
		LET l_cont = 0
        ON EVERY ROW
                
                #INICIO(@#)2-A
                {SELECT inartdesc        INTO l_desc
                FROM tbase:inart
                WHERE inartcart = r.cart}
                LET l_desc="" # (@#)3-A	
                LET l_sql1="SELECT inartdesc ",     
                           " FROM ", f0020_buscar_bd_gb000(0,"S") CLIPPED,":inart",
                           " WHERE inartcart ='", r.cart,"'"
                PREPARE q_inart FROM l_sql1
 		EXECUTE q_inart INTO l_desc
                #FIN(@#)2-A
                #(@#)4-A - INICIO
                {                             
                PRINT 	COLUMN 1,r.ntra USING "<<<<<",
                      	COLUMN 7,r.npre USING "<<<<<<<<<",
                      	COLUMN 18,r.cage USING "<<<<<<<<",
                      	COLUMN 28,r.ftra USING "dd/mm/yyyy",
								COLUMN  40,r.cart CLIPPED,
                     	COLUMN  57,l_desc CLIPPED,
                      	COLUMN  90,r.nser         CLIPPED,
                      	COLUMN 110,f5050_busca_estado_ef233(r.mest)
                                                CLIPPED,
                      	COLUMN 122,r.ftra         USING "dd/mm/yyyy",
			COLUMN 132,f5002_calcular_tiempo_ef233(r.ftra) #(@#)1-B
		}											
								
		PRINT 	COLUMN  1,r.nofi USING "<<<<",							
			COLUMN  11,r.cagp CLIPPED, 									
			COLUMN  25,r.ntra USING "<<<<<<",
			COLUMN  32,r.npre USING "<<<<<<<<<",
			COLUMN  43,r.cage USING "<<<<<<<<",
			COLUMN  54,r.ftra USING "dd/mm/yyyy",
			COLUMN  66,r.cbrp CLIPPED,													
			COLUMN  81,r.cart CLIPPED,
                     	COLUMN  98,l_desc CLIPPED,
                      	COLUMN 	131,r.nser  CLIPPED,
                      	COLUMN 	161,f5050_busca_estado_ef233(r.mest) CLIPPED,
                      	COLUMN 	183,r.ftra         USING "dd/mm/yyyy",
                      	COLUMN 	195, r.capi, 												
			COLUMN 	210,f5002_calcular_tiempo_ef233(r.ftra) #(@#)1-B
		#(@#)4-A - FIN
								
		LET l_cont = l_cont + 1
        AFTER GROUP OF r.csub
                FOR i=1 TO g_ancho-1 PRINT "-"; END FOR PRINT "-"
		PRINT COLUMN 10, "CANTIDAD DE ARTICULOS : ",l_cont USING "###"

		SKIP 1 LINE
		
        PAGE TRAILER
                PRINT ASCII 18
END REPORT

#(@#)5-A - INICIO
REPORT f4101_detalle_impr_d_ef233(r_d)
        DEFINE  r_d               RECORD
              nofi 	INTEGER, -- Numero de agencia
				  cagp 	CHAR(4), -- Descripcion Centro (SAP)
	 			  ntra	INTEGER, -- Numero de Transaccion
	  			  npre	INTEGER, -- Numero de Prestamo
	  			  cage	INTEGER, -- Codigo de Cliente
	  			  ftra	DATE, -- Fecha de Transaccion
	  			  cbrp CHAR(15), -- Codigo BRP
	  			  cart	CHAR(15), -- Codigo de Articulo
	  			  nser	CHAR(35), -- Numero de Serie
	  			  mest	SMALLINT, -- Estado
	  			  capi DECIMAL(8,2), -- Saldo Capital
	  			  csub	SMALLINT, -- Codigo Subtipo de Articulo
				  agen 	CHAR(40),-- Nombre de Oficina
				  nombage CHAR(100),-- Nombre cliente
				  fdes DATE,-- Fecha desembolso
				  mdes decimal(14,2),-- Monto desembolso
				  gtota decimal(14,2), -- Saldo prestamo
				  stat CHAR(200) -- Estado incautado
                                END RECORD,
              l_desc  	CHAR(30), -- Descripcion de articulo
				  l_cont		SMALLINT, -- Variable contador
				  l_sql1          CHAR(100) -- Variable de sentencia 

        OUTPUT
                LEFT MARGIN 0
                TOP  MARGIN 0
                BOTTOM MARGIN 4
                PAGE LENGTH 66
                ORDER EXTERNAL BY r_d.csub
        FORMAT
                PAGE HEADER
             	LET g_ancho  = g_const_340
                LET g_string = t0.gbpmtnemp CLIPPED
                PRINT ASCII 15
                PRINT COLUMN  1,"MODULO EFECTIVA",
                      COLUMN ((g_ancho-length(g_string))/g_const_2),g_string CLIPPED,
                      COLUMN (g_ancho-g_const_9),"PAG: ",PAGENO USING "<<<<"
                LET g_string = "Inventario de Bienes en Dacion en Pago" CLIPPED
                PRINT COLUMN  1,TIME CLIPPED,
                      COLUMN ((g_ancho-length(g_string))/g_const_2),g_string CLIPPED,
                      COLUMN (g_ancho-g_const_9),TODAY USING "dd-mm-yyyy"
                LET g_string = "Al ", p1.fech USING "dd/mm/yyyy"
                PRINT COLUMN  1,"ef233.4gl",
                      COLUMN ((g_ancho-length(g_string))/g_const_2),g_string CLIPPED
                SKIP 1 LINE
                FOR i = g_const_1 TO g_ancho - g_const_1 PRINT "-"; END FOR PRINT "-"
               
                PRINT 	COLUMN  1,"Agencia",							
					   COLUMN  12,"Centro(SAP)",							
             		COLUMN  27,"Trans",					
             		COLUMN  36,"Prestamo",
             	   COLUMN  48,"Cliente",
             	   COLUMN  59,"F.Ingreso",
						COLUMN  72,"Cod. BRP",
						COLUMN  84,"Articulo",
						COLUMN  100,"Descripcion",
             	   COLUMN  135,"Serie",
             	   COLUMN  158,"Estado",
						COLUMN  170,"F.Registro",
						COLUMN  185,"Saldo capital",
						COLUMN  201,"Dias BDP",
						COLUMN  211,"Nombre Oficina",
						COLUMN  227,"Nombre Cliente",
						COLUMN  254,"Fecha Desembolso",
						COLUMN  271,"Monto Desembolso",
						COLUMN  288,"Saldo Prestamo",
						COLUMN  314,"Estado Incautado"	
		     				
                FOR i = g_const_1 TO g_ancho - g_const_1 PRINT "-"; END FOR PRINT "-"
        BEFORE GROUP OF r_d.csub
		LET l_cont = g_const_0
        ON EVERY ROW
                LET l_desc="" 
                LET l_sql1="SELECT inartdesc ",     
                           " FROM ", f0020_buscar_bd_gb000(g_const_0,g_const_s) CLIPPED,":inart",
                           " WHERE inartcart ='", r_d.cart,"'"
                PREPARE q_inart_d FROM l_sql1
 		EXECUTE q_inart_d INTO l_desc
               
								
		PRINT 	COLUMN  3,r_d.nofi USING "<<<<",							
					COLUMN  12,r_d.cagp CLIPPED, 									
					COLUMN  27,r_d.ntra USING "<<<<<<",
					COLUMN  36,r_d.npre USING "<<<<<<<<<",
					COLUMN  48,r_d.cage USING "<<<<<<<<",
					COLUMN  59,r_d.ftra USING "dd/mm/yyyy",
					COLUMN  72,r_d.cbrp CLIPPED,													
					COLUMN  84,r_d.cart CLIPPED,
					COLUMN  100,l_desc CLIPPED,
					COLUMN  135,r_d.nser  CLIPPED,
					COLUMN  158,f5050_busca_estado_ef233(r_d.mest) CLIPPED,
					COLUMN  170,r_d.ftra         USING "dd/mm/yyyy",
					COLUMN  185, r_d.capi, 												
					COLUMN  201,f5002_calcular_tiempo_ef233(r_d.ftra),
					COLUMN  213,r_d.agen CLIPPED,
					COLUMN  225,r_d.nombage CLIPPED,
					COLUMN  258, r_d.fdes USING "dd/mm/yyyy" CLIPPED,
					COLUMN  277, r_d.mdes USING "<<<<<<<<",
					COLUMN 293,r_d.gtota USING "<<<<<<<<",
					COLUMN 305,r_d.stat CLIPPED
		LET l_cont = l_cont + g_const_1
        AFTER GROUP OF r_d.csub
                FOR i = g_const_1 TO g_ancho - g_const_1 PRINT "-"; END FOR PRINT "-"
		PRINT COLUMN 10, "CANTIDAD DE ARTICULOS : ",l_cont USING "###"
		SKIP 1 LINE
        PAGE TRAILER
      PRINT ASCII 18
END REPORT
#(@#)5-A - FIN

#####################
# CONSULTA DE DATOS #
##################### 
FUNCTION f5050_busca_estado_ef233(l_estd)
        DEFINE l_desc   CHAR(20),
                l_estd  SMALLINT

        SELECT gbcondesc INTO l_desc
        FROM gbcon
        WHERE gbconpfij = 101
        AND   gbconcorr = l_estd
        IF STATUS = NOTFOUND THEN
                LET l_desc= " "
        END IF

        RETURN l_desc

END FUNCTION


FUNCTION f5040_busca_gbage_ef233(l_cage)
	DEFINE	l_cage		INTEGER,
		l_nomb		CHAR(25)
	SELECT gbagenomb INTO l_nomb
		FROM gbage
		WHERE gbagecage = l_cage
	IF status = NOTFOUND THEN
		LET l_nomb = " "
	END IF
	RETURN l_nomb
END FUNCTION
FUNCTION f5002_calcular_tiempo_ef233(f_fcan) #(@#)1-B inicio
DEFINE f_fcan DATE,		
			 l_tmp1 SMALLINT
			 
			 LET l_tmp1= 0			
			 LET l_tmp1 = t0.gbpmtfdia- f_fcan
			
	RETURN l_tmp1
END FUNCTION															#(@#)1-B  fin			

#(@#)4-A INICIO
#(@#)4-B - INICIO
#FUNCTION f5002_calcular_saldo_ef233(f_npre, f_capi, f_cart, f_host)
FUNCTION f5002_calcular_saldo_ef233(f_npre, f_capi, f_cart, f_host, f_corr)
#(@#)4-B - FIN 
DEFINE 	f_capi DECIMAL(8,2),
	f_npre INTEGER,
	f_cart CHAR(15),
	f_corr CHAR (15), #(@#)4-B 
	f_host CHAR(30),
	l_tota DECIMAL (12,2),
	l_porc DECIMAL (6,2),
	l_scap DECIMAL (12,2), 
	l_sql CHAR (1000),
	l_sql2 CHAR (1000)
				
	LET l_sql = " SELECT ROUND (SUM (efdticost),2) ",
		" FROM ", f_host ," : efdti  inner join ", f_host , " :efhti ",
		" on efdtintra = efhtintra" ,
		" WHERE efdtitbaj = 0 ",
		" AND efdticgru NOT IN (720,200,201)",
		" AND efhtinpre = ",f_npre,
		" AND efhtimrcb = 0 ",
		" AND efhtiestd IN (1,2) ",
		" AND efhtitdoc = 1 " 
		
		PREPARE q_tota FROM l_sql
 		EXECUTE q_tota INTO l_tota
 			
		IF l_tota=0.00 THEN  LET l_tota=0.01  END IF
		
		LET l_sql2 = " SELECT ROUND(efdticost*100/",l_tota,",2) " ,
			" FROM ", f_host , " : efdti INNER JOIN ",f_host , " :efhti ",  
			" ON efdtintra = efhtintra ",
			" WHERE efhtinpre = ",f_npre ,
			" AND efhtimrcb = 0 ",
			" AND efhtiestd IN (1,2) ",
			" AND efhtitdoc = 1 ",
			" AND efdticart = '", f_cart ,"'",
			" AND efdticgru NOT IN (200,201,720) ",
			" AND efdticorr = '", f_corr ,"'"   #(@#)4-B
		
			PREPARE q_porc FROM l_sql2
 			EXECUTE q_porc INTO l_porc
 									
			LET l_scap = f_capi * (l_porc/100)
			IF l_scap is null then let l_scap = 0 end if
			
	RETURN l_scap    
END FUNCTION	
#(@#)4-A FIN															

#####################
# RUTINAS GENERALES #
#####################

FUNCTION f6000_limpiar_campos_ef233()
			#(@#)5-A - INICIO
       	INITIALIZE t1.*,t1_d.*,p1.* TO NULL
			#(@#)5-A - FIN
			INITIALIZE m1.o1,m1.o2,m1.o3,m1.o4 TO NULL
	INITIALIZE g_tipo TO NULL
        DISPLAY BY NAME m1.*
END FUNCTION

FUNCTION f6050_empresa_ef233()
        SELECT * INTO t0.* FROM gbpmt
	IF status = NOTFOUND OR status < 0 THEN
	   	RETURN FALSE
	END IF
	RETURN TRUE
END FUNCTION

FUNCTION f6100_cabecera_ef233()
      	DEFINE	l_string 	CHAR(33),
                l_empres 	CHAR(33),
                l_sistem 	CHAR(16),
                l_opcion 	CHAR(33),
                l_col    	SMALLINT

	# DISPLAY DEL SISTEMA (16 caracteres)
        LET     l_string = "MODULO EFE"
        LET     l_col = ((16 - length(l_string)) / 2)
        LET     l_sistem = " "
        LET     l_sistem[l_col+1,16-l_col] = l_string
        DISPLAY l_sistem AT 4,2

	# DISPLAY DEL NOMBRE DE LA EMPRESA (33 caracteres)
        LET     l_string = t0.gbpmtnemp CLIPPED
        LET     l_col = ((33 - length(l_string)) / 2)
        LET     l_empres = " "
        LET     l_empres[l_col+1,33-l_col] = l_string
        DISPLAY l_empres AT 4,24

	# DISPLAY DE LA FECHA
        DISPLAY t0.gbpmtfdia AT 4,66

	# DISPLAY DE LA OPCION (33 caracteres)
        LET     l_string = "INVENTARIO FISICO DE INCAUTADOS"
        LET     l_col = ((33 - length(l_string)) / 2)
        LET     l_opcion = " "
        LET     l_opcion[l_col+1,33-l_col] = l_string
        DISPLAY l_opcion AT 5,24
END FUNCTION

FUNCTION f6200_carga_menu_ef233()
   	LET m1.d1 = "Generar e imprimir"
        LET m1.d2 = "Ver en Pantalla"
   	LET m1.d3 = "Repetir Impresion"
   	LET m1.d4 = "Volver Menu anterior"
END FUNCTION

#################
# OTRAS RUTINAS #
#################

FUNCTION f7000_continua_reporte_ef233()
    	DEFINE	l_cont		CHAR(1)
        PROMPT "Enter para continuar" FOR CHAR l_cont 
               ON KEY (CONTROL-C,INTERRUPT)
                  	LET int_flag = TRUE
                  	LET g_opcion = FALSE
        END PROMPT
END FUNCTION
{
## Resumen
         1         2         3         4         5         6         7         8
12345678901234567890123456789012345678901234567890123456789012345678901234567890
Articulo         Descripcion                    Cantid  Series
--------------------------------------------------------------------------------
X-------------X  X------------(30)------------X  #,###  X-------(20)-------X

## Detalle
         1         2         3         4         5         6         7         8
12345678901234567890123456789012345678901234567890123456789012345678901234567890
Cliente  Prest   Nombre                     Articulo        Descripcion      
--------------------------------------------------------------------------------
<<<<<<<< <<<<<<< X---------(25)----------X  X-------------X X-------------------

         9         0         1         2         3
1234567890123456789012345678901234567890123456789012
       Serie                 Estado      F.Ingreso
----------------------------------------------------
----X  X-------(20)-------X  X--------X  dd/mm/yyyy
}

#(@#)5-A - INICIO
FUNCTION f2100_detalle_excel_ef233()
# Descripción: Función que genera el reporte para el formato excel.

MESSAGE "Procesando... un momento por favor!!!"
			IF p1.deta = g_const_n THEN
		  START REPORT imprime_rep_detallado TO g_spool
		  CALL f5000_formato_excel_ef322()
		  IF p1.tipo = g_const_1 THEN
		  FOREACH q_curs_ord1 INTO t1.*
		  		if f3010_busca_traspaso_ef233(t1.npre,t1.cart,t1.nser) then 
					continue foreach
				else
		  			DISPLAY t1.cart TO cart
				end if
        END FOREACH
		  
		  ELSE 
		  FOREACH q_curs_ord2 INTO t1.*
		  		if f3010_busca_traspaso_ef233(t1.npre,t1.cart,t1.nser) then 
					continue foreach
				else
		  			DISPLAY t1.cart TO cart
				end if
        END FOREACH
		  END IF
		  
        FINISH REPORT imprime_rep_detallado
		  
		  ELSE
		  
		  START REPORT imprime_rep_detallado_d TO g_spool
		  CALL f5001_formato_excel_d_ef322()
        
		  IF p1.tipo = g_const_1 THEN
		  
		  FOREACH q_curs_ord1_d INTO t1_d.*
		  		if f3010_busca_traspaso_ef233(t1_d.npre,t1_d.cart,t1_d.nser) then 
					continue foreach
				else
		  			DISPLAY t1_d.cart TO cart
				end if
        END FOREACH
		  
		  ELSE 
		  FOREACH q_curs_ord2_d INTO t1_d.*
		  		if f3010_busca_traspaso_ef233(t1_d.npre,t1_d.cart,t1_d.nser) then 
					continue foreach
				else
		  			DISPLAY t1_d.cart TO cart
				end if
        END FOREACH
		  END IF
		  
        FINISH REPORT imprime_rep_detallado_d
		END IF
END FUNCTION
#(@#)5-A - FIN

#(@#)5-A - INICIO
REPORT imprime_rep_detallado(l_html)
------------------------------------------------------------------------------------------
DEFINE l_html CHAR(18000)
   OUTPUT
      page   length 1
      left   margin 0
      bottom margin 0
      top    margin 0

	 FORMAT ON EVERY ROW
	    PRINT COLUMN 000, l_html CLIPPED
END REPORT

REPORT imprime_rep_detallado_d(l_html)
------------------------------------------------------------------------------------------
DEFINE l_html CHAR(18000)
   OUTPUT
      page   length 1
      left   margin 0
      bottom margin 0
      top    margin 0

	 FORMAT ON EVERY ROW
	    PRINT COLUMN 000, l_html CLIPPED
END REPORT
#(@#)5-A - FIN

#(@#)5-A - INICIO
FUNCTION f5000_formato_excel_ef322()
# Descripción: Función que da el formato xls al reporte.
	DEFINE  
		l_html CHAR(18000), # Cadena de texto para llenado en celdas de excel
      l_titu,l_tita,l_tita_blue,l_tita_black,l_tita_yellow,l_tita_red,l_tita_green,l_tite,l_body	VARCHAR(255), # Estilos de formato para celdas 
      l_today DATE, # Fecha actual
      l_time  DATETIME HOUR TO SECOND, # Hora actual
		l_text	CHAR(30), # Cadena de texto para llenar informacion de agencias
		l_desc	CHAR(30), # Nombre de oficina
		l_sql1  CHAR(500), # Cadena de texto para cursor 
		l_cont SMALLINT, # contador de articulos por tipo
		l_csub SMALLINT # variable de codigo de subtipo de articulos
		
		LET l_today = TODAY 
		LET l_tite = "style=\"color:#000000;background-color:#FFFFFF; font:12px Arial;" # FONDO BLANCO 
		LET l_tita_blue = "style=\"color:#000000;background-color:#94EFE9; font:12px Arial;" # FONDO AZUL
		LET l_tita_black = "style=\"color:#FFFFFF;background-color:#000000; font:12px Arial;" # FONDO NEGRO 
		LET l_tita_yellow = "style=\"color:#000000;background-color:#F5FF38; font:12px Arial;" # FONDO AMARILLO 
		LET l_tita_red = "style=\"color:#FFFFFF;background-color:#C40101; font:12px Arial;" # FONDO ROJO
		LET l_tita_green = "style=\"color:#FFFFFF;background-color:#079333; font:12px Arial;" # FONDO VERDE 
		LET l_body = "style=\"font-family:Arial, Helvetica, sans-serif;font-size:12px;\"" 
		LET l_time = CURRENT 
		LET l_titu  = "style=\"background-color:#E5E5E5;border:0px; font:12px Arial;"
		LET l_tita = "style=\"color:#000000;background-color:#C3C3C3; font:12px Arial;"

		LET l_html=l_html CLIPPED, "<table cellspacing=\"4px\" cellpadding=\"5xp\" border = 0.01 bordercolor=\"black\" >"
		LET l_html=l_html CLIPPED, "<tr>"
		LET l_html=l_html CLIPPED, "<td height= 18px  colspan= 1 ",l_tita_green CLIPPED,"text-align:LEFT;\"></td>"
		LET l_html=l_html CLIPPED, "<td colspan= 12 ",l_tita_green CLIPPED,"text-align:center;\"><b>" ," ", " </b></td>"
		LET l_html=l_html CLIPPED, "<td height = 18px  colspan= 1 ",l_tita_green CLIPPED,"text-align:center;\">", "","</td>"
		LET l_html=l_html CLIPPED, "</tr>"

		LET l_html=l_html CLIPPED, "<tr>"
		LET l_html=l_html CLIPPED, "<td height = 18px  colspan= 1 ",l_tita_green CLIPPED,"text-align:CENTER;\"><b>","MODULO EFECTIVA","</b></td>"
		LET l_html=l_html CLIPPED, "<td colspan = 12 ",l_tita_green CLIPPED,"text-align:center;\"><b>",t0.gbpmtnemp CLIPPED,"</b></td>"
		LET l_html=l_html CLIPPED, "<td height = 18px  colspan= 1 ",l_tita_green CLIPPED,"text-align:CENTER;\"><b>", "FECHA","</b></td>"
		LET l_html=l_html CLIPPED, "</tr>"

		LET l_html=l_html CLIPPED, "<tr>"
		LET l_html=l_html CLIPPED, "<td height=18  colspan= 1 ",l_tita_green CLIPPED,"text-align:CENTER;\"><b>", l_time,"</b></td>"
		LET l_html=l_html CLIPPED, "<td colspan = 12 ",l_tita_green CLIPPED,"text-align:center;\"><b>","Inventario de Bienes en Dacion en Pago" CLIPPED ,"</b></td>"
		LET l_html=l_html CLIPPED, "<td height=18  colspan= 1 ",l_tita_green CLIPPED,"text-align:CENTER;\"><b>",t0.gbpmtfdia USING "dd-mm-yyyy","</b></td>"
		LET l_html=l_html CLIPPED, "</tr>"

		LET l_html=l_html CLIPPED, "<tr>"
		LET l_html=l_html CLIPPED, "<td height=18  colspan= 1 ",l_tita_green CLIPPED,"text-align:CENTER;\"><b>", "ef233.4gl","</b></td>"
		LET l_html=l_html CLIPPED, "<td colspan = 12 ",l_tita_green CLIPPED,"text-align:center;\"><b>" ,"Al ",p1.fech USING "dd/mm/yyyy", "</b></td>"
		LET l_html=l_html CLIPPED, "<td height=18  colspan= 1 ",l_tita_green CLIPPED,"text-align:CENTER;\"><b>","","</b></td>"
		LET l_html=l_html CLIPPED, "</tr>"
		
		LET l_html=l_html CLIPPED, "<table cellspacing=\"2px\" cellpadding=\"2xp\" border = 0.01 bordercolor=\"black\" >"
		LET l_html=l_html CLIPPED, "<tr>"
		LET l_html=l_html CLIPPED, "<td height=18  colspan= 1 ",l_tita_green CLIPPED,"text-align:LEFT;\"></td>"
		LET l_html=l_html CLIPPED, "<td colspan= 12 ",l_tita_green CLIPPED,"text-align:center;\"><b>" ," ", " </b></td>"
		LET l_html=l_html CLIPPED, "<td height=18  colspan= 1 ",l_tita_green CLIPPED,"text-align:center;\">", "","</td>"
		LET l_html=l_html CLIPPED, "</tr>"
      OUTPUT TO REPORT imprime_rep_detallado(l_html)
      
    		LET l_html=""
			LET l_html=l_html CLIPPED, "<table cellspacing=\"2px\" cellpadding=\"2xp\" border = 1 bordercolor=\"black\" >"
    		LET l_html=l_html CLIPPED, "<tr>"
    		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>Agencia</b></td>"
    		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>Centro(SAP)</b></td>"
    		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>Trans</b></td>"
    		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"VERTICal-align:middle;text-align:center;\"><b>Prestamo</b></td>"
    		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>Cliente</b></td>"
    		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>F.Ingreso</b></td>"
    		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>Cod. BRP</b></td>"                   
    		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>Articulo</b></td>"                    
    		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>Descripcion</b></td>"             
    		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>Serie</b></td>"
    		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>Estado</b></td>"
    		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>F.Registro</b></td>"
    		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>Saldo capital</b></td>"
    		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>Dias BDP</b></td>"
    		LET l_html=l_html CLIPPED, "</tr>"
      OUTPUT TO REPORT imprime_rep_detallado(l_html)    
	  LET g_true = g_const_1
	IF p1.tipo = g_const_1 THEN
   	OPEN q_curs_ord1
			WHILE g_true 
			FETCH q_curs_ord1 INTO t1.*
			IF status = g_const_100 THEN
				EXIT WHILE 
			END IF
    			LET l_desc="" 
				LET l_sql1="SELECT inartdesc ",
		           " FROM ", f0020_buscar_bd_gb000(g_const_0,g_const_s) CLIPPED,":inart",
		           " WHERE inartcart ='", t1.cart,"'"
		           PREPARE s_inart_excel FROM l_sql1
			   EXECUTE s_inart_excel INTO l_desc
    			LET l_html="<tr>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1.nofi,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1.cagp,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1.ntra,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1.npre,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1.cage,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1.ftra USING "dd/mm/yyyy","</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1.cbrp,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1.cart,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",l_desc,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1.nser,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",f5050_busca_estado_ef233(t1.mest),"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1.ftra	USING "dd/mm/yyyy","</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1.capi,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",f5002_calcular_tiempo_ef233(t1.ftra),"</td>",
				"</tr>"
      OUTPUT TO REPORT imprime_rep_detallado(l_html)    
     	END WHILE
		
		ELSE
		OPEN q_curs_ord2
		LET l_cont = g_const_0
		LET l_csub = g_const_0
    		WHILE g_true 
    		FETCH q_curs_ord2 INTO t1.*
			IF status = g_const_100 THEN
							EXIT WHILE 
			END IF
    			LET l_desc="" 
				LET l_sql1="SELECT inartdesc ",
		           " FROM ", f0020_buscar_bd_gb000(g_const_0,g_const_s) CLIPPED,":inart",
		           " WHERE inartcart ='", t1.cart,"'"
		           PREPARE s_inart_excel_2 FROM l_sql1
			   EXECUTE s_inart_excel_2 INTO l_desc
				IF l_csub<>t1.csub THEN
						LET l_html="<tr>",
							"<td colspan=14 align=LEFT>","CANTIDAD DE ARTICULOS: ",l_cont,"</td>",
						"</tr>"
					OUTPUT TO REPORT imprime_rep_detallado(l_html)
					LET l_csub = t1.csub
					LET l_cont = g_const_0
				END IF
    			LET l_html="<tr>",

    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1.nofi,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1.cagp,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1.ntra,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1.npre,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1.cage,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1.ftra USING "dd/mm/yyyy","</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1.cbrp,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1.cart,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",l_desc,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1.nser,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",f5050_busca_estado_ef233(t1.mest),"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1.ftra	USING "dd/mm/yyyy","</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1.capi,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",f5002_calcular_tiempo_ef233(t1.ftra),"</td>",
				"</tr>"
      OUTPUT TO REPORT imprime_rep_detallado(l_html)    
			IF l_csub<>t1.csub THEN
						LET l_html="<tr>",
							"<td colspan=14 align=LEFT>","CANTIDAD DE ARTICULOS: ",l_cont,"</td>",
						"</tr>"
					OUTPUT TO REPORT imprime_rep_detallado(l_html)
					LET l_cont = g_const_0
			END IF
			LET l_cont = l_cont + g_const_1
			LET l_csub = t1.csub
     	END WHILE
		LET l_html="<tr>",
							"<td colspan=14 align=LEFT>","CANTIDAD DE ARTICULOS: ",l_cont,"</td>",
						"</tr>"
				OUTPUT TO REPORT imprime_rep_detallado(l_html)
		END IF
    		LET l_html = "</table></body></HTML>"
      OUTPUT TO REPORT imprime_rep_detallado(l_html)    

END FUNCTION
#(@#)5-A - FIN

#(@#)5-A - INICIO
FUNCTION f5001_formato_excel_d_ef322()
# Descripción: Función que da el formato xls al reporte detallado.
	DEFINE  
		l_html CHAR(18000), # Cadena de texto para llenado en celdas de excel
      l_titu,l_tita,l_tita_blue,l_tita_black,l_tita_yellow,l_tita_red,l_tita_green,l_tite,l_body	VARCHAR(255), # Estilos de formato para celdas 
      l_today DATE, # Fecha actual
      l_time  DATETIME HOUR TO SECOND, # Hora actual
		l_text	CHAR(30), # Cadena de texto para llenar informacion de agencias
		l_desc	CHAR(30), # Nombre de oficina
		l_sql1  CHAR(500), # Cadena de texto para cursor 
		l_cont_d SMALLINT, # contador de articulos por tipo
		l_csub_d SMALLINT # variable de codigo de subtipo de articulos

		LET l_today = TODAY 
		LET l_tite = "style=\"color:#000000;background-color:#FFFFFF; font:12px Arial;" # FONDO BLANCO 
		LET l_tita_blue = "style=\"color:#000000;background-color:#94EFE9; font:12px Arial;" # FONDO AZUL
		LET l_tita_black = "style=\"color:#FFFFFF;background-color:#000000; font:12px Arial;" # FONDO NEGRO 
		LET l_tita_yellow = "style=\"color:#000000;background-color:#F5FF38; font:12px Arial;" # FONDO AMARILLO 
		LET l_tita_red = "style=\"color:#FFFFFF;background-color:#C40101; font:12px Arial;" # FONDO ROJO
		LET l_tita_green = "style=\"color:#FFFFFF;background-color:#079333; font:12px Arial;" # FONDO VERDE 
		LET l_body = "style=\"font-family:Arial, Helvetica, sans-serif;font-size:12px;\"" 
		LET l_time = CURRENT 

		LET l_titu  = "style=\"background-color:#E5E5E5;border:0px; font:12px Arial;"
		LET l_tita = "style=\"color:#000000;background-color:#C3C3C3; font:12px Arial;"

		LET l_html=l_html CLIPPED, "<table cellspacing=\"4px\" cellpadding=\"5xp\" border = 0.01 bordercolor=\"black\" >"
		
		LET l_html=l_html CLIPPED, "<tr>"
		LET l_html=l_html CLIPPED, "<td height= 18px  colspan= 1 ",l_tita_green CLIPPED,"text-align:LEFT;\"></td>"
		LET l_html=l_html CLIPPED, "<td colspan= 18 ",l_tita_green CLIPPED,"text-align:center;\"><b>" ," ", " </b></td>"
		LET l_html=l_html CLIPPED, "<td height = 18px  colspan= 1 ",l_tita_green CLIPPED,"text-align:center;\">", "","</td>"
		LET l_html=l_html CLIPPED, "</tr>"

		LET l_html=l_html CLIPPED, "<tr>"
		LET l_html=l_html CLIPPED, "<td height = 18px  colspan= 1 ",l_tita_green CLIPPED,"text-align:CENTER;\"><b>","MODULO EFECTIVA","</b></td>"
		LET l_html=l_html CLIPPED, "<td colspan = 18 ",l_tita_green CLIPPED,"text-align:center;\"><b>",t0.gbpmtnemp CLIPPED,"</b></td>"
		LET l_html=l_html CLIPPED, "<td height = 18px  colspan= 1 ",l_tita_green CLIPPED,"text-align:CENTER;\"><b>", "FECHA","</b></td>"
		LET l_html=l_html CLIPPED, "</tr>"

		LET l_html=l_html CLIPPED, "<tr>"
		LET l_html=l_html CLIPPED, "<td height=18  colspan= 1 ",l_tita_green CLIPPED,"text-align:CENTER;\"><b>", l_time,"</b></td>"
		LET l_html=l_html CLIPPED, "<td colspan = 18 ",l_tita_green CLIPPED,"text-align:center;\"><b>","Inventario de Bienes en Dacion en Pago" CLIPPED ,"</b></td>"
		LET l_html=l_html CLIPPED, "<td height=18  colspan= 1 ",l_tita_green CLIPPED,"text-align:CENTER;\"><b>",t0.gbpmtfdia USING "dd-mm-yyyy","</b></td>"
		LET l_html=l_html CLIPPED, "</tr>"

		LET l_html=l_html CLIPPED, "<tr>"
		LET l_html=l_html CLIPPED, "<td height=18  colspan= 1 ",l_tita_green CLIPPED,"text-align:CENTER;\"><b>", "ef233.4gl","</b></td>"
		LET l_html=l_html CLIPPED, "<td colspan = 18 ",l_tita_green CLIPPED,"text-align:center;\"><b>" ,"Al ",p1.fech USING "dd/mm/yyyy", "</b></td>"
		LET l_html=l_html CLIPPED, "<td height=18  colspan= 1 ",l_tita_green CLIPPED,"text-align:CENTER;\"><b>","","</b></td>"
		LET l_html=l_html CLIPPED, "</tr>"
		
		LET l_html=l_html CLIPPED, "<table cellspacing=\"2px\" cellpadding=\"2xp\" border = 0.01 bordercolor=\"black\" >"
		LET l_html=l_html CLIPPED, "<tr>"
		LET l_html=l_html CLIPPED, "<td height=18  colspan= 1 ",l_tita_green CLIPPED,"text-align:LEFT;\"></td>"
		LET l_html=l_html CLIPPED, "<td colspan= 18 ",l_tita_green CLIPPED,"text-align:center;\"><b>" ," ", " </b></td>"
		LET l_html=l_html CLIPPED, "<td height=18  colspan= 1 ",l_tita_green CLIPPED,"text-align:center;\">", "","</td>"
		LET l_html=l_html CLIPPED, "</tr>"
      OUTPUT TO REPORT imprime_rep_detallado_d(l_html)
			
		LET l_html=""
		LET l_html=l_html CLIPPED, "<table cellspacing=\"2px\" cellpadding=\"2xp\" border = 1 bordercolor=\"black\" >"
		LET l_html=l_html CLIPPED, "<tr>"
		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>Agencia</b></td>"
		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>Centro(SAP)</b></td>"
		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>Trans</b></td>"
		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"VERTICal-align:middle;text-align:center;\"><b>Prestamo</b></td>"
		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>Cliente</b></td>"
		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>F.Ingreso</b></td>"
		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>Cod. BRP</b></td>"                   
		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>Articulo</b></td>"                    
		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>Descripcion</b></td>"             
		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>Serie</b></td>"
		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>Estado</b></td>"
		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>F.Registro</b></td>"
		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>Saldo capital</b></td>"
		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>Dias BDP</b></td>"
		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>Nombre Oficina</b></td>"             
		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>Nombre Cliente</b></td>"
		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>Fecha Desembolso</b></td>"
		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>Monto Desembolso</b></td>"
		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>Saldo Prestamo</b></td>"
		LET l_html=l_html CLIPPED, " <td height=25  colspan= 1 ",l_tita CLIPPED,"vertical-align:middle;text-align:center;\"><b>Estado Incautado</b></td>"
    	LET l_html=l_html CLIPPED, "</tr>"

      OUTPUT TO REPORT imprime_rep_detallado_d(l_html)    
			LET g_true = g_const_1
	IF p1.tipo = g_const_1 THEN
   	OPEN q_curs_ord1_d
			WHILE g_true 
			FETCH q_curs_ord1_d INTO t1_d.*
			IF status = g_const_100 THEN
				EXIT WHILE 
			END IF
			
    			LET l_desc="" 
				LET l_sql1="SELECT inartdesc ",
		           " FROM ", f0020_buscar_bd_gb000(g_const_0,g_const_s) CLIPPED,":inart",
		           " WHERE inartcart ='", t1_d.cart,"'"
		           PREPARE s_inart_excel_d FROM l_sql1
			   EXECUTE s_inart_excel_d INTO l_desc
    			LET l_html="<tr>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.nofi,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.cagp,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.ntra,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.npre,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.cage,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.ftra USING "dd/mm/yyyy","</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.cbrp,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.cart,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",l_desc,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.nser,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",f5050_busca_estado_ef233(t1_d.mest),"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.ftra	USING "dd/mm/yyyy","</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.capi,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",f5002_calcular_tiempo_ef233(t1_d.ftra),"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.agen,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.nombage,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.fdes USING "dd/mm/yyyy","</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.mdes,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.gtota,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.stat,"</td>",
    			"</tr>"
      OUTPUT TO REPORT imprime_rep_detallado_d(l_html)    
     	END WHILE
    		ELSE

		OPEN q_curs_ord2_d
		LET l_cont_d = g_const_0
		LET l_csub_d = g_const_0
    		WHILE g_true 
    		FETCH q_curs_ord2_d INTO t1_d.*
			IF status = g_const_100 THEN
			EXIT WHILE 
			END IF
		LET l_desc="" 
				LET l_sql1="SELECT inartdesc ",
		           " FROM ", f0020_buscar_bd_gb000(g_const_0,g_const_s) CLIPPED,":inart",
		           " WHERE inartcart ='", t1_d.cart,"'"
		           PREPARE s_inart_excel_d2 FROM l_sql1
			   EXECUTE s_inart_excel_d2 INTO l_desc
				IF l_csub_d<>t1_d.csub THEN
						LET l_html="<tr>",
							"<td colspan=14 align=LEFT>","CANTIDAD DE ARTICULOS: ",l_cont_d,"</td>",
						"</tr>"
					OUTPUT TO REPORT imprime_rep_detallado_d(l_html)
					LET l_csub_d = t1_d.csub
					LET l_cont_d = g_const_0
				END IF
    			LET l_html="<tr>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.nofi,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.cagp,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.ntra,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.npre,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.cage,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.ftra USING "dd/mm/yyyy","</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.cbrp,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.cart,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",l_desc,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.nser,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",f5050_busca_estado_ef233(t1_d.mest),"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.ftra	USING "dd/mm/yyyy","</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.capi,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",f5002_calcular_tiempo_ef233(t1_d.ftra),"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.agen,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.nombage,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.fdes USING "dd/mm/yyyy","</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.mdes,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.gtota,"</td>",
    			" <td height=25  colspan= 1 ",l_tite CLIPPED,"vertical-align:middle;text-align:center;\">",t1_d.stat,"</td>",
				"</tr>"
      OUTPUT TO REPORT imprime_rep_detallado_d(l_html)    
		IF l_csub_d<>t1_d.csub THEN
						LET l_html="<tr>",
							"<td colspan=14 align=LEFT>","CANTIDAD DE ARTICULOS: ",l_cont_d,"</td>",
						"</tr>"
					OUTPUT TO REPORT imprime_rep_detallado_d(l_html)
					LET l_cont_d = g_const_0
				END IF
				LET l_cont_d = l_cont_d + g_const_1
				LET l_csub_d = t1_d.csub
     END WHILE
	  LET l_html="<tr>",
							"<td colspan=14 align=LEFT>","CANTIDAD DE ARTICULOS: ",l_cont_d,"</td>",
						"</tr>"
						OUTPUT TO REPORT imprime_rep_detallado_d(l_html)
	  END IF
    		LET l_html = "</table></body></HTML>"
      OUTPUT TO REPORT imprime_rep_detallado_d(l_html)    
END FUNCTION
#(@#)5-A - FIN