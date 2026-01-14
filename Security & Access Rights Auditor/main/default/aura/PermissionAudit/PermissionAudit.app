<!--
Author     : Tejas K. Kshirsagar
Description: This App is Responsible to Display Lightning Component Named AuditApp.cmp in VF page Named AuditApp.vfp
-->
<aura:application extends="ltng:outApp" access="GLOBAL" >
      <ltng:require styles="{!$Resource.AuditAppCss}" />
	  <aura:dependency resource="c:AuditApp"/>
</aura:application>