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
###############################################################################                                                                                
DATABASE tbsfi
	DEFINE	p1		RECORD
				  fech	DATE,
				  tipo	SMALLINT 
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
		g_tipo		CHAR(1),
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
	CALL f0300_proceso_ef233()
END MAIN

###########################
# DECLARACION DE PUNTEROS #
###########################

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
		l_sql CHAR(500), 	
		l_sql1 CHAR(500),	
		l_sql2 CHAR(1000),			
		l1 RECORD 
			efhtintra LIKE efhti.efhtintra,
			efhtinpre LIKE efhti.efhtinpre,
			efhticage LIKE efhti.efhticage,
			efhtiftra LIKE efhti.efhtiftra,
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
							
				FOREACH c_cursor_01 INTO l1.*,l_egbhctcagp, l_gbofihos
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

	IF p1.tipo = 1 THEN
			DECLARE q_curs_ord1 CURSOR FOR 
			SELECT gbofinofi,egbhctcagp,efhtintra,efhtinpre,efhticage,efhtiftra,efdticorr,
				efdticart,efdtinser,efdtimest,efhticapi,efdticsub
			FROM tmp_01 
			ORDER BY 1,3
			
	ELSE
		DECLARE q_curs_ord2 CURSOR FOR 
			SELECT 
				gbofinofi,egbhctcagp,efhtintra,efhtinpre,efhticage,efhtiftra,efdticorr,
				efdticart,efdtinser,efdtimest,efhticapi,efdticsub 
			FROM tmp_01 
			ORDER BY 1,12
			
	END IF 																								
#(@#)4-A - FIN
END FUNCTION

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
                        	    IF f0400_pedir_datos_ef233() THEN
					IF p1.tipo = 1 THEN
						CALL f3000_detalle_ef233()
					ELSE
						CALL f4000_detalle_subg_ef233()
					END IF
                             		CALL f0100_imprimir_gb001(g_spool)
                          	    END IF
                          	    CALL f2295_temporal_ef233('D')				#(@#)4-A
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
       	INITIALIZE t1.*,p1.* TO NULL
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
