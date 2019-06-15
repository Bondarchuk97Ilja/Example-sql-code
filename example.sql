-- Рабочие дни менеджеров

select t2.manager_ldap,
       t2.date_create  
  into #WORK_DAYS	   
  from dialogsBase as t1
  join empHistData as t2 on t2.date_create  = t1.date_create
                        and t2.manager_ldap = t1.manager_ldap
			and date(t2.date_create) between dateformat(today(),'yyyy-mm-01') and today()
 where t2.PEOP_STATE not in ('болеет', 'в отпуске', 'в командировке', 'отсутствует') 
;
commit;

--Принадлежность менеджеров

select t1.manager_ldap,
       t1.manager_name,
       t2.LDAP_LINE_MANAGER,
       trim(t3.CONT_VALUE) as "CL_PHONE_LINE_MANAGER"
  into #MANAGER_ADRESS
  from dialogsBase      as t1
  join empData          as t2 on t2.manager_ldap = t1.manager_ldap
  join empContactData   as t3 on t3.ldap         = t2.LDAP_LINE_MANAGER
                             and t3.CONT_MAIN    = 1
  join contactDirectory as t4 on t4.CONT_TYPE    = t3.CONT_TYPE 
                             and t4.CONT_NAME    = 'PHONE'  
;
commit;

-- Звонки менеджеров

select month(t2.date_create)   as "MONTH"
       t2.manager_ldap,
       t1.RPBranch,
       t1.RPName,
       sum(t1.totalDialogsNum) as "Sum_dialogs", 
       sum(t1.totalAccepted)   as "Sum_accepted"
  into #ALL_DIALOGS	   
  from dialogsBase as t1
  join #WORK_DAYS  as t2 on t2.date_create  = t1.date_create
                        and t2.manager_ldap = t1.manager_ldap 
 group by MONTH,
          t2.manager_ldap,
          t1.RPBranch,
	  t1.RPName111
;
commit;

--Добавляем долю

select t1.*,
       cast(1.00 * t1.Sum_accepted / t1.Sum_dialogs  as numeric (8,2)) as "PART_ACCEPTED"
  into #PART_DIALOGS
  from #ALL_DIALOGS as t1	
 ;
commit;

--Проводим ранги

select t1.MONTH,
       t1.manager_ldap,
       t1.RPBranch,
       t1.RPName,
       t1.Sum_dialogs,
       t1.Sum_accepted,
       t1.PART_ACCEPTED,
       rank () over (partiton by t1.RPBranch, t1.RPName order by t1.PART_ACCEPTED asc) as "WORTH_MANAGER"
  into #TURNIRKA
  from #PART_DIALOGS as t1
;
commit;

--Финальный селект

select t2.manager_ldap          as "Логин менеджера",
       t2.manager_name          as "ФИО менеджера",
       t2.LDAP_LINE_MANAGER     as "Логин линейного руководителя",
       t2.CL_PHONE_LINE_MANAGER as "Основной телефон руководителя",
       t1.RPBranch              as "Бранч РП",
       t1.RPName                as "Наименование РП", 
       t1.Sum_dialogs           as "Кол-во диалогов всего",
       t1.Sum_accepted          as "Кол-во принятых диалогов",
       t1.PART_ACCEPTED         as "Доля принятых диалогов"
  from #TURNIRKA        as t1
  join #MANAGER_ADRESS  as t2 on t2.manager_ldap = t1.manager_ldap
 where WORTH_MANAGER <= 5
 ;
 commit;
 
	   
	
	
	
 
 
