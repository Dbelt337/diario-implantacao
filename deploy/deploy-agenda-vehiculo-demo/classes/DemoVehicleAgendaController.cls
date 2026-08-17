/**
 * Agenda of a demo vehicle, for the consultant, WITHOUT the customer name.
 *
 * All countries. Backs the demoVehicleAgenda Lightning web component placed on
 * the Service Resource or Asset record page. Returns the test drive and service
 * appointments booked against a vehicle, showing vehicle, date, time, status and
 * the person responsible for the reservation.
 *
 * WHY THIS IS APEX AND NOT FIELD LEVEL SECURITY.
 * Measured on the org: ServiceAppointment.ParentRecordId has isPermissionable
 * false, so no profile or permission set can hide it, and on a test drive it
 * points at the prospect's Lead or Opportunity. Hiding ContactId alone leaves
 * the customer reachable through the parent. The only enforceable way to meet
 * the requirement is projection: the server never selects the customer, so
 * there is no field to hide and no record to click through to.
 *
 * The SELECT list below is the security control. Do not add fields to it
 * without reading the note above. Deliberately excluded, and each one would
 * break the requirement:
 *     ContactId, ParentRecordId, AccountId  - identify the customer
 *     Subject, Description                  - free text, usually carries the name
 *     Address, Street, City, PostalCode     - the customer's address on home test drives
 *
 * The query runs in an inner class marked without sharing on purpose: the
 * consultant must see the unit's whole agenda, including bookings made by
 * colleagues, which record level access would otherwise hide. What protects the
 * customer here is the projection, not the sharing model.
 */
public with sharing class DemoVehicleAgendaController {

    public class AgendaException extends Exception {}

    /**
     * One row of the agenda. Only safe fields.
     */
    public class AgendaRow {
        @AuraEnabled public String appointmentId;
        @AuraEnabled public String appointmentNumber;
        @AuraEnabled public String vehicle;
        @AuraEnabled public Datetime startTime;
        @AuraEnabled public Datetime endTime;
        @AuraEnabled public String status;
        @AuraEnabled public String workType;
        @AuraEnabled public String territory;
        @AuraEnabled public String owner;
        @AuraEnabled public String createdBy;
    }

    /**
     * Returns the agenda of the vehicle behind the given record.
     *
     * @param recordId  a ServiceResource of type Asset, or an Asset that is
     *                  linked to one. Any other object is rejected.
     * @return          the appointments booked against that vehicle, oldest
     *                  scheduled start first. Never contains customer data.
     */
    @AuraEnabled(cacheable=true)
    public static List<AgendaRow> getAgenda(Id recordId) {
        if (recordId == null) { return new List<AgendaRow>(); }
        try {
            return new Elevated().read(recordId);
        } catch (AgendaException e) {
            throw new AuraHandledException(e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('No se pudo leer la agenda: ' + e.getMessage());
        }
    }

    /**
     * Runs without sharing so the whole agenda of the unit is visible, and
     * keeps the field projection that protects the customer.
     */
    private without sharing class Elevated {

        public List<AgendaRow> read(Id recordId) {
            Id resourceId = resolveResource(recordId);
            String vehicleName = resourceName(resourceId);

            Set<Id> appointmentIds = new Set<Id>();
            for (AssignedResource ar : [
                    SELECT ServiceAppointmentId
                    FROM AssignedResource
                    WHERE ServiceResourceId = :resourceId
                    LIMIT 2000]) {
                appointmentIds.add(ar.ServiceAppointmentId);
            }
            if (appointmentIds.isEmpty()) { return new List<AgendaRow>(); }

            // THE SECURITY CONTROL. See the class header before changing it.
            List<ServiceAppointment> appointments = [
                SELECT Id, AppointmentNumber, Status, SchedStartTime, SchedEndTime,
                       OwnerId, CreatedBy.Name, WorkType.Name, ServiceTerritory.Name
                FROM ServiceAppointment
                WHERE Id IN :appointmentIds AND SchedStartTime != null
                ORDER BY SchedStartTime
                LIMIT 2000];

            Map<Id, String> ownerNames = new Map<Id, String>();
            Set<Id> ownerIds = new Set<Id>();
            for (ServiceAppointment sa : appointments) {
                if (sa.OwnerId != null) { ownerIds.add(sa.OwnerId); }
            }
            // OwnerId is polymorphic, User or Queue. Only users are resolved,
            // a queue owner shows blank instead of failing the whole card.
            if (!ownerIds.isEmpty()) {
                for (User u : [SELECT Id, Name FROM User WHERE Id IN :ownerIds]) {
                    ownerNames.put(u.Id, u.Name);
                }
            }

            List<AgendaRow> rows = new List<AgendaRow>();
            for (ServiceAppointment sa : appointments) {
                AgendaRow r = new AgendaRow();
                r.appointmentId     = sa.Id;
                r.appointmentNumber = sa.AppointmentNumber;
                r.vehicle           = vehicleName;
                r.startTime         = sa.SchedStartTime;
                r.endTime           = sa.SchedEndTime;
                r.status            = sa.Status;
                r.workType          = sa.WorkType == null ? null : sa.WorkType.Name;
                r.territory         = sa.ServiceTerritory == null ? null : sa.ServiceTerritory.Name;
                r.owner             = ownerNames.get(sa.OwnerId);
                r.createdBy         = sa.CreatedBy == null ? null : sa.CreatedBy.Name;
                rows.add(r);
            }
            return rows;
        }

        /**
         * Accepts a ServiceResource directly, which is unambiguous, or an Asset,
         * in which case the lookup from ServiceResource to Asset is discovered
         * by describe instead of hardcoded, because that link is not the same in
         * every org.
         *
         * There is deliberately NO fallback to matching by name. On a privacy
         * feature, showing the agenda of the wrong car is worse than showing
         * nothing, so this fails loudly instead.
         */
        private Id resolveResource(Id recordId) {
            String objectName = recordId.getSObjectType().getDescribe().getName();

            if (objectName == 'ServiceResource') { return recordId; }

            if (objectName != 'Asset') {
                throw new AgendaException(
                    'Este componente funciona en Service Resource o en Asset, no en ' + objectName + '.');
            }

            String lookupField = null;
            for (Schema.SObjectField f : ServiceResource.SObjectType.getDescribe().fields.getMap().values()) {
                Schema.DescribeFieldResult d = f.getDescribe();
                if (d.getType() != Schema.DisplayType.REFERENCE) { continue; }
                for (Schema.SObjectType t : d.getReferenceTo()) {
                    if (t.getDescribe().getName() == 'Asset') { lookupField = d.getName(); }
                }
            }
            if (lookupField == null) {
                throw new AgendaException(
                    'ServiceResource no tiene ningun campo que apunte a Asset en esta org. '
                    + 'Coloque el componente en la pagina del Service Resource del vehiculo.');
            }

            List<SObject> found = Database.query(
                'SELECT Id FROM ServiceResource WHERE ' + lookupField + ' = :recordId'
                + ' AND IsActive = true LIMIT 1');
            if (found.isEmpty()) {
                throw new AgendaException(
                    'Este vehiculo no tiene un Service Resource activo, entonces no es '
                    + 'agendable y no tiene agenda.');
            }
            return (Id) found[0].get('Id');
        }

        private String resourceName(Id resourceId) {
            List<ServiceResource> rs = [SELECT Name FROM ServiceResource WHERE Id = :resourceId LIMIT 1];
            return rs.isEmpty() ? null : rs[0].Name;
        }
    }
}
