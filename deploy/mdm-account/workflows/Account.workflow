<?xml version="1.0" encoding="UTF-8"?>
<!--
  Acoes do Approval Process (declarativas, sem Apex).
  - 2 Field Updates para ligar/desligar a flag anti-loop ApprovalInProgress__c.
  - 1 Task de revisao manual disparada na Rejeicao Final (nao da pra reverter
    automaticamente os dados sem campos-sombra; como NAO usamos campos de
    trazabilidade, a reversao e' manual e o Data Steward e' avisado por Task).
  reevaluateOnChange=false: o field update nao deve reabrir regras de workflow.
-->
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>MDM_Set_ApprovalInProgress_True</fullName>
        <field>ApprovalInProgress__c</field>
        <literalValue>true</literalValue>
        <name>MDM Set ApprovalInProgress True</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>MDM_Set_ApprovalInProgress_False</fullName>
        <field>ApprovalInProgress__c</field>
        <literalValue>false</literalValue>
        <name>MDM Set ApprovalInProgress False</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <tasks>
        <fullName>MDM_Reverter_Dados_Sensiveis</fullName>
        <assignedToType>owner</assignedToType>
        <description>A solicitacao de alteracao de dados sensiveis desta conta foi REJEITADA no Approval Process de MDM. Reverter manualmente os campos sensiveis ao valor anterior aprovado. (Reversao automatica nao e' possivel sem campos de trazabilidade, que foram intencionalmente nao criados.)</description>
        <dueDateInterval>1</dueDateInterval>
        <notifyAssignee>true</notifyAssignee>
        <priority>High</priority>
        <protected>false</protected>
        <status>Not Started</status>
        <subject>MDM: aprovacao rejeitada - reverter dados sensiveis manualmente</subject>
    </tasks>
</Workflow>
