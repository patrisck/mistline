using UnityEngine;

public class DoorInteractable : MonoBehaviour, IInteractable
{
    public void Interact()
    {
        Debug.Log("Door interacted - Opening");
    }
}