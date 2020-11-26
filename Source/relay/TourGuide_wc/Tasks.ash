import "relay/TourGuide_wc/Support/Checklist.ash"
import "relay/TourGuide_wc/Support/Library.ash"
import "relay/TourGuide_wc/Plants.ash"
import "relay/TourGuide_wc/Support/HTML.ash"
import "relay/TourGuide_wc/Sets.ash"

void generateTasks(Checklist [int] checklists)
{
	ChecklistEntry [int] task_entries;
	
	ChecklistEntry [int] optional_task_entries;
		
	ChecklistEntry [int] future_task_entries;
	
	QuestsGenerateTasks(task_entries, optional_task_entries, future_task_entries);
	SetsGenerateTasks(task_entries, optional_task_entries, future_task_entries);
    
	checklists.listAppend(ChecklistMake("Tasks", task_entries));
	checklists.listAppend(ChecklistMake("Optional Tasks", optional_task_entries));
	checklists.listAppend(ChecklistMake("Future Tasks", future_task_entries));
}